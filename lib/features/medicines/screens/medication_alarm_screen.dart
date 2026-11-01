import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/page_content.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAlarmAudio());
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
    if (widget.notificationId != null) {
      try {
        await ref
            .read(notificationServiceProvider)
            .cancel(widget.notificationId!);
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
      if (!mounted) return;
      if (widget.closeActivityOnDismiss) {
        // This Activity was opened by Android for the alarm. Finish it so the
        // previous app or the lock screen is restored instead of showing Home.
        try {
          await _alarmAudio.invokeMethod<void>('finishAlarmActivity', {
            'notificationId': widget.notificationId,
          });
          return;
        } on PlatformException {
          // Fall through to a navigator pop for nonstandard Android builds.
        } on MissingPluginException {
          // Fall through only in environments without the native activity.
        }
      }

      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && context.canPop()) {
        context.pop();
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
