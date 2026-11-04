import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../features/medicines/models/medication.dart';
import '../../../features/medicines/providers/medications_provider.dart';
import '../../../features/doses/models/dose_record.dart';
import '../../../features/doses/providers/doses_provider.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/notifications/notification_ids.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/dose_summary.dart';
import '../../../shared/widgets/page_content.dart';
import '../../../shared/widgets/postpone_duration_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;
  Timer? _minuteTimer;

  void _watchDate() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextDay.difference(now), () {
      if (mounted) {
        setState(() {});
        _watchDate();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchDate();
    _startMinuteTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refreshNotifications(),
    );
  }

  void _startMinuteTimer() {
    _minuteTimer?.cancel();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
        final now = DateTime.now();
        ref.invalidate(
          dosesForDateProvider(DateTime(now.year, now.month, now.day)),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _minuteTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _watchDate();
      _startMinuteTimer();
      ref.invalidate(medicationsProvider);
      _refreshNotifications();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _minuteTimer?.cancel();
    }
  }

  Future<void> _refreshNotifications() async {
    try {
      await ref.read(notificationSchedulerProvider).reconcile();
    } catch (_) {
      // Do not block the dashboard if Android notification services are unavailable.
    }
  }

  Future<void> _updateDose(DoseRecord dose, DoseStatus status) async {
    try {
      await ref.read(doseRepositoryProvider).setStatus(dose.id, status);
      await ref
          .read(notificationServiceProvider)
          .cancel(postponedNotificationIdBase + dose.id);
      final now = DateTime.now();
      ref.invalidate(
        dosesForDateProvider(DateTime(now.year, now.month, now.day)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).medicationLoadError),
          ),
        );
      }
    }
  }

  Future<void> _postponeDose(DoseRecord dose) async {
    final isArabic = AppLocalizations.of(context).localeName.startsWith('ar');
    final minutes = await showPostponeDurationSheet(
      context: context,
      title:
          isArabic
              ? '\u062a\u0623\u062c\u064a\u0644 \u062a\u0630\u0643\u064a\u0631 \u0627\u0644\u062c\u0631\u0639\u0629'
              : 'Snooze dose reminder',
      minuteOptions: const [10, 30, 60],
      minuteLabelBuilder:
          (minutes) =>
              isArabic
                  ? '\u0628\u0639\u062f $minutes \u062f\u0642\u064a\u0642\u0629'
                  : 'In $minutes minutes',
    );
    if (minutes == null) return;
    try {
      await ref
          .read(doseRepositoryProvider)
          .postponeDose(
            dose.id,
            DateTime.now().toUtc().add(Duration(minutes: minutes)),
          );
      await ref
          .read(notificationSchedulerProvider)
          .schedulePostponedDose(dose.id);
      final now = DateTime.now();
      ref.invalidate(
        dosesForDateProvider(DateTime(now.year, now.month, now.day)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).medicationLoadError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final medicationState = ref.watch(medicationsProvider);
    final nowDate = DateTime.now();
    final localDate = DateTime(nowDate.year, nowDate.month, nowDate.day);
    final doseState = ref.watch(dosesForDateProvider(localDate));
    final items = <_TodayReminder>[];
    final medications = medicationState.asData?.value;
    final doseRecords = doseState.asData?.value;
    if (medications != null && doseRecords != null) {
      for (final dose in doseRecords) {
        final medication =
            medications
                .where((item) => item.id == dose.medicationId)
                .firstOrNull;
        if (medication == null) continue;
        final scheduled = dose.scheduledAt;
        items.add(
          _TodayReminder(medication, scheduled.hour, scheduled.minute, dose),
        );
      }
    }
    final now = TimeOfDay.now();
    final nextReminder =
        items.where((item) => _atOrAfter(item, now)).firstOrNull;

    return PageContent(
      storageKey: 'home',
      backgroundGradient: false,
      children: [
        Text(
          DateFormat.yMMMMEEEEd(l10n.localeName).format(DateTime.now()),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        PageHeading(title: l10n.greeting, subtitle: l10n.welcome),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.nextReminder,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  medicationState.isLoading
                      ? l10n.loading
                      : nextReminder == null
                      ? (items.isEmpty
                          ? l10n.noReminder
                          : l10n.allRemindersPassed)
                      : TimeOfDay(
                        hour: nextReminder.hour,
                        minute: nextReminder.minute,
                      ).format(context),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nextReminder?.medication.name ?? l10n.noReminderBody,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (nextReminder != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed:
                        () => context.push(
                          '/medications/${nextReminder.medication.id}',
                        ),
                    icon: const Icon(Icons.medication_outlined),
                    label: Text(l10n.medicineDetails),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.todayOverview, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(14) > 22;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width:
                      stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 14) / 2,
                  child: _Metric(
                    icon: Icons.schedule_rounded,
                    label: l10n.scheduledToday,
                    value: medicationState.isLoading ? null : items.length,
                  ),
                ),
                SizedBox(
                  width:
                      stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 14) / 2,
                  child: _Metric(
                    icon: Icons.check_circle_outline_rounded,
                    label: l10n.confirmedToday,
                    value:
                        doseState.asData?.value
                            .where((dose) => dose.status == DoseStatus.taken)
                            .length,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        if (doseRecords != null && items.isNotEmpty) ...[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end:
                  doseRecords
                      .where((d) => d.status == DoseStatus.taken)
                      .length /
                  items.length,
            ),
            duration:
                MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
            builder:
                (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1),
                    minHeight: 8,
                    semanticsLabel: l10n.confirmedToday,
                  ),
                ),
          ),
          const SizedBox(height: 24),
        ],
        Text(l10n.todaySchedule, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        medicationState.when(
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (_, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: l10n.medicationLoadError,
                message: l10n.medicationLoadError,
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(medicationsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retryDatabase),
                ),
              ),
          data:
              (_) =>
                  items.isEmpty
                      ? EmptyState(
                        icon: Icons.event_available_outlined,
                        title: l10n.noDosesTitle,
                        message: l10n.noRemindersToday,
                        action: FilledButton.icon(
                          onPressed: () => context.go('/medications'),
                          icon: const Icon(Icons.medication_outlined),
                          label: Text(l10n.viewMedications),
                        ),
                      )
                      : Column(
                        children: items
                            .map(
                              (item) => _ReminderCard(
                                item: item,
                                onStatus: _updateDose,
                                onPostpone: _postponeDose,
                              ),
                            )
                            .toList(growable: false),
                      ),
        ),
      ],
    );
  }
}

class _TodayReminder {
  const _TodayReminder(this.medication, this.hour, this.minute, this.dose);
  final Medication medication;
  final int hour;
  final int minute;
  final DoseRecord dose;
}

bool _atOrAfter(_TodayReminder item, TimeOfDay now) =>
    item.hour * 60 + item.minute >= now.hour * 60 + now.minute;

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final int? value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            value == null
                ? '—'
                : NumberFormat.decimalPattern(
                  Localizations.localeOf(context).languageCode,
                ).format(value),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.item,
    required this.onStatus,
    required this.onPostpone,
  });
  final _TodayReminder item;
  final Future<void> Function(DoseRecord, DoseStatus) onStatus;
  final Future<void> Function(DoseRecord) onPostpone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        item.medication.colorValue == null
            ? theme.colorScheme.primary
            : Color(item.medication.colorValue!);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 12),
        child: Column(
          children: [
            DoseSummary(
              onTap:
                  item.medication.id == null
                      ? null
                      : () =>
                          context.push('/medications/${item.medication.id}'),
              name: item.medication.name,
              description:
                  '${item.medication.dosageAmount} ${item.medication.dosageUnit} \u00b7 ${_doseStatusLabel(context, item.dose.status)}',
              time: TimeOfDay(
                hour: item.hour,
                minute: item.minute,
              ).format(context),
              icon:
                  item.dose.status == DoseStatus.taken
                      ? Icons.check_circle_outline_rounded
                      : Icons.medication_outlined,
              color: color,
            ),
            if (item.dose.scheduledAtUtc <=
                    DateTime.now().toUtc().millisecondsSinceEpoch &&
                item.dose.status != DoseStatus.taken &&
                item.dose.status != DoseStatus.skipped)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => onStatus(item.dose, DoseStatus.taken),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(AppLocalizations.of(context).markTaken),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onStatus(item.dose, DoseStatus.skipped),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: Text(AppLocalizations.of(context).markSkipped),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onPostpone(item.dose),
                    icon: const Icon(Icons.snooze_rounded),
                    label: Text(
                      AppLocalizations.of(context).localeName.startsWith('ar')
                          ? 'تأجيل'
                          : 'Postpone',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _doseStatusLabel(BuildContext context, DoseStatus status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    DoseStatus.taken => l10n.taken,
    DoseStatus.postponed =>
      l10n.localeName.startsWith('ar') ? 'مؤجلة' : 'Postponed',
    DoseStatus.skipped => l10n.skipped,
    DoseStatus.unconfirmed || DoseStatus.missed =>
      l10n.localeName.startsWith('ar') ? 'غير مؤكدة' : 'Unconfirmed',
    DoseStatus.pending => l10n.pending,
  };
}
