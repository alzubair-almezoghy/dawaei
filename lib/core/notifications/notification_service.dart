import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/settings/models/app_settings.dart';

typedef MedicationNotificationTap =
    void Function(
      int medicationId,
      int? notificationId,
      bool launchedApplication,
    );

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _nativeChannel = MethodChannel(
    'app.dawaei.dawaei/medication_alarm',
  );
  MedicationNotificationTap? _onMedicationTap;
  final ValueNotifier<bool> hasPendingMedicationAlarm = ValueNotifier(false);
  int? _pendingMedicationId;
  int? _pendingNotificationId;
  bool _pendingLaunchedApplication = false;
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> initialize() async {
    if (_initialized) return;
    final activeAttempt = _initializing;
    if (activeAttempt != null) {
      await activeAttempt;
      return;
    }
    final attempt = _initializeOnce();
    _initializing = attempt;
    try {
      await attempt;
    } catch (_) {
      if (identical(_initializing, attempt)) _initializing = null;
      rethrow;
    }
  }

  Future<void> _initializeOnce() async {
    timezone_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(
          '@drawable/dawaei_notification',
        ),
      ),
      onDidReceiveNotificationResponse:
          (response) => _dispatchPayload(response.payload, response.id),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _dispatchPayload(
        launch?.notificationResponse?.payload,
        launch?.notificationResponse?.id,
        launchedApplication: true,
      );
    }
    _initialized = true;
  }

  set onMedicationTap(MedicationNotificationTap? callback) {
    _onMedicationTap = callback;
    final pending = _pendingMedicationId;
    if (pending != null && callback != null) {
      _pendingMedicationId = null;
      callback(pending, _pendingNotificationId, _pendingLaunchedApplication);
      _pendingNotificationId = null;
      _pendingLaunchedApplication = false;
      hasPendingMedicationAlarm.value = false;
    }
  }

  Future<String> refreshDeviceTimezone() async {
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(deviceZone.identifier);
    tz.setLocalLocation(location);
    return deviceZone.identifier;
  }

  Future<bool> notificationsEnabled() async =>
      await _android()?.areNotificationsEnabled() ?? false;

  Future<bool> requestNotificationsPermission() async =>
      await _android()?.requestNotificationsPermission() ?? false;

  Future<bool> canScheduleExact() async =>
      await _android()?.canScheduleExactNotifications() ?? false;

  Future<bool> canUseFullScreenIntent() async {
    try {
      return await _nativeChannel.invokeMethod<bool>(
            'canUseFullScreenIntent',
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> shouldCloseActivityForAlarm() async {
    try {
      return await _nativeChannel.invokeMethod<bool>(
            'shouldCloseAlarmActivity',
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await _nativeChannel.invokeMethod<bool>(
            'isBatteryOptimizationIgnored',
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openBatterySettings() =>
      _nativeChannel.invokeMethod<void>('openBatterySettings');

  Future<void> openNotificationChannelSettings(AppSettings settings) async {
    final policyAccess = await hasNotificationPolicyAccess();
    final bypassDnd = settings.medicationAlertsDuringDnd && policyAccess;
    final channelId = _channelId(settings, bypassDnd);
    await _ensureAlertChannel(settings, bypassDnd);
    await _nativeChannel.invokeMethod<void>('openNotificationChannelSettings', {
      'channelId': channelId,
    });
  }

  Future<bool> hasNotificationPolicyAccess() async =>
      await _android()?.hasNotificationPolicyAccess() ?? false;

  Future<bool> requestNotificationPolicyAccess() async =>
      await _android()?.requestNotificationPolicyAccess() ?? false;

  Future<bool> requestExactAlarmPermission() async =>
      await _android()?.requestExactAlarmsPermission() ?? false;

  Future<bool> requestFullScreenPermission() async =>
      await _android()?.requestFullScreenIntentPermission() ?? false;

  Future<void> schedule({
    required int id,
    required String medicationName,
    required String dosageAmount,
    required String dosageUnit,
    required int medicationId,
    required tz.TZDateTime at,
    required bool exact,
    required AppSettings alertSettings,
  }) async {
    await initialize();
    if (!await notificationsEnabled()) {
      throw StateError('Notification permission is not enabled');
    }
    final policyAccess = await hasNotificationPolicyAccess();
    final bypassDnd = alertSettings.medicationAlertsDuringDnd && policyAccess;
    final channelId = _channelId(alertSettings, bypassDnd);
    await _ensureAlertChannel(alertSettings, bypassDnd);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        // Notification channel sound and audio usage are immutable after the
        // channel is created, so this new id applies alarm-stream behavior to
        // existing installs as well as fresh installs.
        channelId,
        alertSettings.medicationAlertMode == MedicationAlertMode.alarm
            ? 'Medication alarms'
            : 'Medication reminders',
        channelDescription: 'Medication time reminders.',
        icon: 'dawaei_notification',
        largeIcon: const DrawableResourceAndroidBitmap('dawaei_logo_icon'),
        playSound: true,
        sound: _sound(alertSettings),
        audioAttributesUsage:
            alertSettings.medicationAlertMode == MedicationAlertMode.alarm
                ? AudioAttributesUsage.alarm
                : AudioAttributesUsage.notification,
        channelBypassDnd: bypassDnd,
        enableVibration: alertSettings.medicationAlertVibration,
        vibrationPattern: Int64List.fromList([0, 600, 300, 600]),
        additionalFlags:
            alertSettings.medicationAlertMode == MedicationAlertMode.alarm
                ? Int32List.fromList([4]) // Android FLAG_INSISTENT.
                : null,
        timeoutAfter: 60000,
        fullScreenIntent:
            alertSettings.medicationAlertMode == MedicationAlertMode.alarm,
        autoCancel: true,
        importance:
            alertSettings.medicationAlertMode == MedicationAlertMode.alarm
                ? Importance.max
                : Importance.high,
        priority:
            alertSettings.medicationAlertMode == MedicationAlertMode.alarm
                ? Priority.max
                : Priority.high,
        visibility: NotificationVisibility.private,
        category:
            alertSettings.medicationAlertMode == MedicationAlertMode.alarm
                ? AndroidNotificationCategory.alarm
                : AndroidNotificationCategory.reminder,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      medicationName,
      '$dosageAmount $dosageUnit',
      at,
      details,
      androidScheduleMode:
          exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({'medicationId': medicationId}),
    );
  }

  Future<void> testAlert(
    AppSettings alertSettings, {
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!await notificationsEnabled()) {
      throw StateError('Notification permission is not enabled');
    }
    final policyAccess = await hasNotificationPolicyAccess();
    final bypassDnd = alertSettings.medicationAlertsDuringDnd && policyAccess;
    await _ensureAlertChannel(alertSettings, bypassDnd);
    final details = AndroidNotificationDetails(
      _channelId(alertSettings, bypassDnd),
      alertSettings.medicationAlertMode == MedicationAlertMode.alarm
          ? 'Medication alarms'
          : 'Medication reminders',
      channelDescription: 'Medication time reminders.',
      icon: 'dawaei_notification',
      largeIcon: const DrawableResourceAndroidBitmap('dawaei_logo_icon'),
      playSound: true,
      sound: _sound(alertSettings),
      audioAttributesUsage:
          alertSettings.medicationAlertMode == MedicationAlertMode.alarm
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
      channelBypassDnd: bypassDnd,
      enableVibration: alertSettings.medicationAlertVibration,
      vibrationPattern: Int64List.fromList([0, 600, 300, 600]),
      importance:
          alertSettings.medicationAlertMode == MedicationAlertMode.alarm
              ? Importance.max
              : Importance.high,
      priority:
          alertSettings.medicationAlertMode == MedicationAlertMode.alarm
              ? Priority.max
              : Priority.high,
      category:
          alertSettings.medicationAlertMode == MedicationAlertMode.alarm
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.reminder,
      timeoutAfter: 10000,
    );
    await _plugin.show(
      2147483000,
      title,
      body,
      NotificationDetails(android: details),
    );
  }

  static AndroidNotificationSound? _sound(AppSettings settings) =>
      settings.medicationAlertSound == MedicationAlertSound.dawaei
          ? const RawResourceAndroidNotificationSound('medication_alarm')
          : null;

  static String _channelId(AppSettings settings, bool bypassDnd) =>
      'medication_${settings.medicationAlertMode.name}_'
      '${settings.medicationAlertSound.name}_'
      '${settings.medicationAlertVibration ? 'vibrate' : 'quiet'}_'
      // Android locks channel audio attributes after first creation. Bump this
      // version whenever channel sound behavior changes so existing installs
      // get a fresh channel instead of staying silently stuck on old settings.
      '${bypassDnd ? 'dnd' : 'normal'}_v2';

  Future<void> _ensureAlertChannel(AppSettings settings, bool bypassDnd) async {
    await _android()?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId(settings, bypassDnd),
        settings.medicationAlertMode == MedicationAlertMode.alarm
            ? 'Medication alarms'
            : 'Medication reminders',
        description: 'Medication time reminders.',
        importance:
            settings.medicationAlertMode == MedicationAlertMode.alarm
                ? Importance.max
                : Importance.high,
        playSound: true,
        sound: _sound(settings),
        audioAttributesUsage:
            settings.medicationAlertMode == MedicationAlertMode.alarm
                ? AudioAttributesUsage.alarm
                : AudioAttributesUsage.notification,
        bypassDnd: bypassDnd,
        enableVibration: settings.medicationAlertVibration,
        vibrationPattern: Int64List.fromList([0, 600, 300, 600]),
      ),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<List<PendingNotificationRequest>> pendingRequests() =>
      _plugin.pendingNotificationRequests();

  AndroidFlutterLocalNotificationsPlugin? _android() =>
      _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  void _dispatchPayload(
    String? payload,
    int? notificationId, {
    bool launchedApplication = false,
  }) {
    if (payload == null || payload.isEmpty) return;
    try {
      final value = jsonDecode(payload) as Map<String, dynamic>;
      final id = value['medicationId'];
      if (id is! int || id <= 0) return;
      final callback = _onMedicationTap;
      if (callback == null) {
        _pendingMedicationId = id;
        _pendingNotificationId = notificationId;
        _pendingLaunchedApplication = launchedApplication;
        hasPendingMedicationAlarm.value = true;
      } else {
        callback(id, notificationId, launchedApplication);
      }
    } on FormatException {
      // Ignore payloads from earlier app versions that are not valid JSON.
    } on TypeError {
      // Ignore malformed payloads rather than interrupting application startup.
    }
  }
}
