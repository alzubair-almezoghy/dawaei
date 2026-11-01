import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/page_content.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _saving = false;
  bool? _notificationsAllowed;
  bool? _exactAlarmsAllowed;
  bool? _fullScreenAllowed;
  bool? _dndAccessAllowed;
  bool? _batteryOptimizationIgnored;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationStatus();
      _reconcileNotifications();
    }
  }

  Future<void> _reconcileNotifications() async {
    try {
      await ref.read(notificationSchedulerProvider).reconcile();
    } catch (_) {
      // Keep settings usable if Android temporarily rejects a reschedule.
    }
  }

  Future<void> _refreshNotificationStatus() async {
    List<bool> statuses;
    try {
      final service = ref.read(notificationServiceProvider);
      statuses = await Future.wait([
        service.notificationsEnabled(),
        service.canScheduleExact(),
        service.canUseFullScreenIntent(),
        service.hasNotificationPolicyAccess(),
        service.isBatteryOptimizationIgnored(),
      ]);
    } catch (_) {
      statuses = const [false, false, false, false, false];
    }
    if (!mounted) return;
    setState(() {
      _notificationsAllowed = statuses[0];
      _exactAlarmsAllowed = statuses[1];
      _fullScreenAllowed = statuses[2];
      _dndAccessAllowed = statuses[3];
      _batteryOptimizationIgnored = statuses[4];
    });
  }

  Future<void> _testMedicationAlert() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(notificationServiceProvider)
          .testAlert(
            ref.read(settingsProvider).requireValue,
            title: l10n.medicationAlertSettings,
            body: l10n.testAlertSent,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.testAlertSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.testAlertError)));
      }
    }
  }

  Future<void> _setDndPreference(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    if (!enabled) {
      await _save(() async {
        await ref
            .read(settingsProvider.notifier)
            .setMedicationAlertsDuringDnd(false);
        await ref.read(notificationSchedulerProvider).reconcile();
        await _refreshNotificationStatus();
      });
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.confirmDndTitle),
            content: Text(l10n.confirmDndBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.continueAction),
              ),
            ],
          ),
    );
    if (approved != true || !mounted) return;
    await _save(() async {
      final controller = ref.read(settingsProvider.notifier);
      await controller.setMedicationAlertsDuringDnd(true);
      if (_dndAccessAllowed != true) {
        await ref
            .read(notificationServiceProvider)
            .requestNotificationPolicyAccess();
      }
      await _refreshNotificationStatus();
      await ref.read(notificationSchedulerProvider).reconcile();
    });
  }

  Future<void> _save(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).settingsSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).requireValue;
    final controller = ref.read(settingsProvider.notifier);
    return PageContent(
      storageKey: 'settings',
      backgroundGradient: false,
      children: [
        PageHeading(title: l10n.personalize, subtitle: l10n.settingsSubtitle),
        Card(
          child: ListTile(
            leading: const Icon(Icons.diversity_1_outlined),
            title: Text(l10n.manageCareRecipients),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/care-recipients'),
          ),
        ),
        const SizedBox(height: 24),
        AppSectionHeader(title: l10n.language, icon: Icons.language_outlined),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _ChoiceTile(
                key: const Key('language-ar'),
                title: l10n.arabic,
                selected: settings.languageCode == 'ar',
                enabled: !_saving,
                onTap: () => _save(() => controller.setLanguage('ar')),
              ),
              const Divider(indent: 20, endIndent: 20),
              _ChoiceTile(
                key: const Key('language-en'),
                title: l10n.english,
                selected: settings.languageCode == 'en',
                enabled: !_saving,
                onTap: () => _save(() => controller.setLanguage('en')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppSectionHeader(title: l10n.appearance, icon: Icons.palette_outlined),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final mode in ThemeMode.values) ...[
                if (mode != ThemeMode.system)
                  const Divider(indent: 20, endIndent: 20),
                _ChoiceTile(
                  key: Key('theme-${mode.name}'),
                  title: switch (mode) {
                    ThemeMode.system => l10n.system,
                    ThemeMode.light => l10n.light,
                    ThemeMode.dark => l10n.dark,
                  },
                  selected: settings.themeMode == mode,
                  enabled: !_saving,
                  onTap: () => _save(() => controller.setTheme(mode)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppSectionHeader(
          title: l10n.medicationAlertSettings,
          icon: Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.medicationAlertSettings),
                subtitle: Text(l10n.medicationAlertSettingsBody),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: SegmentedButton<MedicationAlertMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: MedicationAlertMode.standard,
                      label: Text(l10n.standardReminderMode),
                    ),
                    ButtonSegment(
                      value: MedicationAlertMode.alarm,
                      label: Text(l10n.alarmReminderMode),
                    ),
                  ],
                  selected: {settings.medicationAlertMode},
                  onSelectionChanged:
                      (selection) => _save(() async {
                        await controller.setMedicationAlertMode(
                          selection.single,
                        );
                        await ref
                            .read(notificationSchedulerProvider)
                            .reconcile();
                      }),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                child: Text(
                  l10n.reminderModeHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                title: Text(l10n.reminderSound),
                trailing: DropdownButton<MedicationAlertSound>(
                  value: settings.medicationAlertSound,
                  onChanged:
                      _saving
                          ? null
                          : (sound) {
                            if (sound == null) return;
                            _save(() async {
                              await controller.setMedicationAlertSound(sound);
                              await ref
                                  .read(notificationSchedulerProvider)
                                  .reconcile();
                            });
                          },
                  items: [
                    DropdownMenuItem(
                      value: MedicationAlertSound.dawaei,
                      child: Text(l10n.dawaeiReminderSound),
                    ),
                    DropdownMenuItem(
                      value: MedicationAlertSound.system,
                      child: Text(l10n.systemReminderSound),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: Text(l10n.reminderVibration),
                value: settings.medicationAlertVibration,
                onChanged:
                    _saving
                        ? null
                        : (enabled) => _save(() async {
                          await controller.setMedicationAlertVibration(enabled);
                          await ref
                              .read(notificationSchedulerProvider)
                              .reconcile();
                        }),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _saving ? null : _testMedicationAlert,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: Text(l10n.testMedicationAlert),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _saving
                            ? null
                            : () => _save(() async {
                              await ref
                                  .read(notificationServiceProvider)
                                  .openNotificationChannelSettings(settings);
                            }),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(l10n.openNotificationChannelSettings),
                  ),
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              SwitchListTile(
                title: Text(l10n.allowAlertsDuringDnd),
                subtitle: Text(
                  _dndAccessAllowed == true
                      ? l10n.dndAccessGranted
                      : l10n.dndAccessNeeded,
                ),
                value: settings.medicationAlertsDuringDnd,
                onChanged: _saving ? null : _setDndPreference,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                child: Text(
                  l10n.dndAccessHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: Text(l10n.fullScreenAlarmStatus),
                subtitle: Text(
                  _fullScreenAllowed == null
                      ? l10n.permissionUnknown
                      : _fullScreenAllowed!
                      ? l10n.fullScreenAllowed
                      : l10n.fullScreenUnavailable,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                child: Text(
                  l10n.fullScreenHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _saving || _fullScreenAllowed == true
                            ? null
                            : () => _save(() async {
                              await ref
                                  .read(notificationServiceProvider)
                                  .requestFullScreenPermission();
                              await _refreshNotificationStatus();
                              await ref
                                  .read(notificationSchedulerProvider)
                                  .reconcile();
                            }),
                    child: Text(l10n.openFullScreenSettings),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                child: Text(
                  l10n.silentModeHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(
                  _notificationsAllowed == null
                      ? l10n.permissionUnknown
                      : _notificationsAllowed!
                      ? l10n.notificationsAllowed
                      : l10n.notificationsBlocked,
                ),
                subtitle: Text(l10n.notificationSettingsBody),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed:
                        _saving
                            ? null
                            : () => _save(() async {
                              await ref
                                  .read(notificationServiceProvider)
                                  .requestNotificationsPermission();
                              await ref
                                  .read(notificationSchedulerProvider)
                                  .reconcile();
                              await _refreshNotificationStatus();
                            }),
                    child: Text(l10n.allowNotifications),
                  ),
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: const Icon(Icons.alarm_on_outlined),
                title: Text(l10n.exactAlarmSettings),
                subtitle: Text(
                  _exactAlarmsAllowed == null
                      ? l10n.permissionUnknown
                      : _exactAlarmsAllowed!
                      ? l10n.exactAlarmsAllowed
                      : l10n.exactAlarmsBlocked,
                ),
                isThreeLine: true,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _saving || _exactAlarmsAllowed == true
                            ? null
                            : () => _save(() async {
                              await ref
                                  .read(notificationServiceProvider)
                                  .requestExactAlarmPermission();
                              await _refreshNotificationStatus();
                              await ref
                                  .read(notificationSchedulerProvider)
                                  .reconcile();
                            }),
                    child: Text(l10n.openExactAlarmSettings),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                child: Text(
                  l10n.exactAlarmSettingsBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: const Icon(Icons.battery_saver_outlined),
                title: Text(
                  _batteryOptimizationIgnored == true
                      ? l10n.batteryOptimizationIgnored
                      : l10n.batteryOptimizationActive,
                ),
                subtitle: Text(l10n.batteryOptimizationHelp),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _saving
                            ? null
                            : () => _save(() async {
                              await ref
                                  .read(notificationServiceProvider)
                                  .openBatterySettings();
                            }),
                    child: Text(l10n.openBatterySettings),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppSectionHeader(
          title: l10n.privacyAndAbout,
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                minVerticalPadding: 18,
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.privacy),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                ),
                onTap: () => context.push('/privacy'),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                minVerticalPadding: 18,
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.about),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                ),
                onTap: () => context.push('/about'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${l10n.foundationVersion} · ${AppInfo.versionLabel}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.disclaimer,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.8),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: ListTile(
      title: Text(title),
      enabled: enabled,
      minVerticalPadding: 18,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: selected ? null : onTap,
    ),
  );
}
