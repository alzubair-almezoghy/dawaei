import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/notifications/notification_ids.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/page_content.dart';
import '../../../shared/widgets/postpone_duration_sheet.dart';
import '../../doses/models/dose_record.dart';
import '../../doses/providers/doses_provider.dart';
import '../widgets/medication_image_preview.dart';
import '../providers/medications_provider.dart';
import '../../settings/models/app_settings.dart';
import '../../settings/providers/settings_provider.dart';

class MedicationAlarmScreen extends ConsumerStatefulWidget {
  const MedicationAlarmScreen({
    required this.medicationId,
    this.notificationId,
    this.closeActivityOnDismiss = false,
    super.key,
  });
  final int medicationId;
  final int? notificationId;
  final bool closeActivityOnDismiss;

  @override
  ConsumerState<MedicationAlarmScreen> createState() =>
      _MedicationAlarmScreenState();
}

class _MedicationAlarmScreenState extends ConsumerState<MedicationAlarmScreen> {
  static const _alarmAudio = MethodChannel(
    'app.dawaei.dawaei/medication_alarm',
  );
  bool _busy = false;
  bool _dismissed = false;
  bool _allowPop = false;
  bool _doseLoading = true;
  DoseRecord? _dose;
  int? _activeNotificationId;

  @override
  void initState() {
    super.initState();
    _activeNotificationId = widget.notificationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAlarmAudio();
      _loadDose();
    });
  }

  Future<void> _loadDose() async {
    try {
      final dose = await ref
          .read(doseRepositoryProvider)
          .findDoseForAlarm(
            medicationId: widget.medicationId,
            notificationId: widget.notificationId,
          );
      if (mounted) {
        setState(() {
          _dose = dose;
          _doseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _doseLoading = false);
    }
  }

  Future<void> _startAlarmAudio() async {
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!mounted || _dismissed) return;
      if (settings.medicationAlertMode != MedicationAlertMode.alarm ||
          settings.medicationAlertSound != MedicationAlertSound.dawaei) {
        return;
      }
      await _alarmAudio.invokeMethod<void>('start');
    } on PlatformException {
      // Notification sound and vibration remain available if native playback fails.
    } on MissingPluginException {
      // The route may be shown in a non-Android preview environment.
    }
  }

  Future<void> _stopAlarmAndNotification() async {
    try {
      await _alarmAudio.invokeMethod<void>('stop');
    } on PlatformException {
      // Keep cleaning up if native audio already stopped or is unavailable.
    } on MissingPluginException {
      // This route can also be shown in preview/test environments.
    }
    if (_activeNotificationId != null) {
      try {
        await ref
            .read(notificationServiceProvider)
            .cancel(_activeNotificationId!);
      } catch (_) {
        // Closing the alarm screen must not depend on notification cleanup.
      }
    }
  }

  Future<void> _dismissAlarm() async {
    if (_busy) return;
    _dismissed = true;
    setState(() => _busy = true);
    try {
      await _stopAlarmAndNotification();
      await _closeAlarmRoute();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closeAlarmRoute({bool cancelNotification = true}) async {
    if (!mounted) return;
    if (widget.closeActivityOnDismiss) {
      try {
        await _alarmAudio.invokeMethod<void>('finishAlarmActivity', {
          'notificationId': cancelNotification ? _activeNotificationId : null,
        });
        return;
      } on PlatformException {
        // Fall through to route pop if the native activity cannot finish.
      } on MissingPluginException {
        // Fall through in non-Android preview environments.
      }
    }
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && context.canPop()) context.pop();
  }

  Future<void> _restoreAlarmAfterCanceledPostpone(DoseRecord dose) async {
    _dismissed = false;
    final notificationId =
        _activeNotificationId ?? postponedNotificationIdBase + dose.id;
    _activeNotificationId = notificationId;
    try {
      final medication =
          ref
              .read(medicationsProvider)
              .asData
              ?.value
              .where((item) => item.id == widget.medicationId)
              .firstOrNull;
      final settings = await ref.read(settingsProvider.future);
      if (medication != null) {
        await ref
            .read(notificationServiceProvider)
            .restoreAlarmNotification(
              id: notificationId,
              medicationId: widget.medicationId,
              medicationName: medication.name,
              dosageAmount: medication.dosageAmount,
              dosageUnit: medication.dosageUnit,
              alertSettings: settings,
            );
      }
    } catch (_) {
      // Keep the current alarm screen and restart native playback below.
    }
    await _startAlarmAudio();
  }

  Future<int?> _choosePostponeMinutes() {
    final isArabic = AppLocalizations.of(context).localeName.startsWith('ar');
    return showPostponeDurationSheet(
      context: context,
      title:
          isArabic
              ? '\u062a\u0623\u062c\u064a\u0644 \u062a\u0630\u0643\u064a\u0631 \u0627\u0644\u062c\u0631\u0639\u0629'
              : 'Snooze dose reminder',
      minuteOptions: const [5, 10, 15, 30],
      minuteLabelBuilder:
          (minutes) =>
              isArabic
                  ? '\u0628\u0639\u062f $minutes \u062f\u0642\u064a\u0642\u0629'
                  : 'In $minutes minutes',
      customLabel:
          isArabic
              ? '\u0648\u0642\u062a \u0645\u062e\u0635\u0635'
              : 'Custom time',
      showDragHandle: true,
    );
  }

  Future<DateTime?> _postponeTime() async {
    final choice = await _choosePostponeMinutes();
    if (choice == null) return null;
    if (!mounted) return null;
    final now = DateTime.now();
    if (choice > 0) return now.toUtc().add(Duration(minutes: choice));
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))),
    );
    if (selected == null) return null;
    var local = DateTime(
      now.year,
      now.month,
      now.day,
      selected.hour,
      selected.minute,
    );
    if (!local.isAfter(now)) local = local.add(const Duration(days: 1));
    return local.toUtc();
  }

  Future<void> _postponeAlarm() async {
    final dose = _dose;
    if (_busy || dose == null) return;
    setState(() => _busy = true);
    _dismissed = true;
    await _stopAlarmAndNotification();
    try {
      final until = await _postponeTime();
      if (!mounted) return;
      if (until == null) {
        await _restoreAlarmAfterCanceledPostpone(dose);
        return;
      }
      // Schedule first. If Android rejects the request, the dose record stays
      // unchanged and the alarm interface can be restored.
      await ref
          .read(notificationSchedulerProvider)
          .schedulePostponedDose(dose.id, untilUtc: until);
      try {
        await ref.read(doseRepositoryProvider).postponeDose(dose.id, until);
      } catch (_) {
        await ref
            .read(notificationServiceProvider)
            .cancel(postponedNotificationIdBase + dose.id);
        rethrow;
      }
      final now = DateTime.now();
      ref.invalidate(
        dosesForDateProvider(DateTime(now.year, now.month, now.day)),
      );
      await _closeAlarmRoute(cancelNotification: false);
    } catch (_) {
      if (mounted) {
        await _restoreAlarmAfterCanceledPostpone(dose);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).localeName.startsWith('ar')
                  ? 'تعذر جدولة التذكير. لم يتم تأجيل الجرعة.'
                  : 'Could not schedule the reminder. The dose was not postponed.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markDoseTaken() async {
    final dose = _dose;
    if (_busy || dose == null) return;
    setState(() => _busy = true);
    _dismissed = true;
    try {
      await ref
          .read(doseRepositoryProvider)
          .setStatus(dose.id, DoseStatus.taken);
      final now = DateTime.now();
      ref.invalidate(
        dosesForDateProvider(DateTime(now.year, now.month, now.day)),
      );
      await ref
          .read(notificationServiceProvider)
          .cancel(postponedNotificationIdBase + dose.id);
      await _stopAlarmAndNotification();
      await _closeAlarmRoute();
    } catch (_) {
      if (mounted) {
        _dismissed = false;
        await _startAlarmAudio();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).medicationLoadError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewDose() async {
    if (_busy) return;
    _dismissed = true;
    setState(() => _busy = true);
    await _stopAlarmAndNotification();
    if (mounted) context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final medications = ref.watch(medicationsProvider);
    final medication =
        medications.asData?.value
            .where((item) => item.id == widget.medicationId)
            .firstOrNull;
    return PopScope(
      canPop: _allowPop,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground(theme.brightness),
        body: PageContent(
          children: [
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: .72),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.alarm_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.alarmTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TimeOfDay.now().format(context),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (medication != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (medication.imagePath != null)
                        MedicationImagePreview(
                          path: medication.imagePath,
                          temporary: false,
                          height: 158,
                          placeholder: Icon(
                            Icons.medication_rounded,
                            size: 42,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else
                        Icon(
                          Icons.medication_rounded,
                          size: 30,
                          color: theme.colorScheme.primary,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        medication.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${medication.dosageAmount} ${medication.dosageUnit}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (medications.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 20),
            Text(
              l10n.alarmConfirmationNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            if (_doseLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_dose != null &&
                _dose!.status != DoseStatus.taken &&
                _dose!.status != DoseStatus.skipped) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _markDoseTaken,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(l10n.markTaken),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _postponeAlarm,
                  icon: const Icon(Icons.snooze_rounded),
                  label: Text(
                    l10n.localeName.startsWith('ar') ? 'تأجيل' : 'Postpone',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _dismissAlarm,
                icon: const Icon(Icons.volume_off_outlined),
                label: Text(l10n.stopAlarm),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _reviewDose,
                icon: const Icon(Icons.history_rounded),
                label: Text(l10n.reviewDose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
