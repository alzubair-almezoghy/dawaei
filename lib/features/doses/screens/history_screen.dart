import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/doses/models/dose_record.dart';
import '../../../features/doses/providers/doses_provider.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/notifications/notification_ids.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/dose_summary.dart';
import '../../../shared/widgets/page_content.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());
  bool _monthly = false;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTimeRange get _range {
    if (_monthly) {
      final start = DateTime(_selectedDate.year, _selectedDate.month);
      return DateTimeRange(
        start: start,
        end: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
      );
    }
    final start = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return DateTimeRange(start: start, end: start.add(const Duration(days: 6)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final doses = ref.watch(dosesForDateProvider(_selectedDate));
    final summary = ref.watch(adherenceSummaryProvider(_range));
    final today = _dateOnly(DateTime.now());
    final direction = Directionality.of(context);

    return PageContent(
      storageKey: 'history',
      backgroundGradient: false,
      children: [
        PageHeading(title: l10n.historyTitle, subtitle: l10n.historySubtitle),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.week)),
            ButtonSegment(value: true, label: Text(l10n.month)),
          ],
          selected: {_monthly},
          onSelectionChanged:
              (selection) => setState(() => _monthly = selection.single),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.previousDay,
                  onPressed:
                      () => setState(
                        () =>
                            _selectedDate = _selectedDate.subtract(
                              const Duration(days: 1),
                            ),
                      ),
                  icon: Icon(
                    direction == ui.TextDirection.rtl
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (chosen != null) {
                        setState(() => _selectedDate = _dateOnly(chosen));
                      }
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      DateFormat.yMMMMEEEEd(locale).format(_selectedDate),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextDay,
                  onPressed:
                      _selectedDate.isBefore(today)
                          ? () => setState(
                            () =>
                                _selectedDate = _selectedDate.add(
                                  const Duration(days: 1),
                                ),
                          )
                          : null,
                  icon: Icon(
                    direction == ui.TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _AdherenceCard(summary: summary, monthly: _monthly),
        const SizedBox(height: 24),
        Text(l10n.doseHistory, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        doses.when(
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (_, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: l10n.medicationLoadError,
                message: l10n.medicationLoadError,
                action: FilledButton.icon(
                  onPressed:
                      () => ref.invalidate(dosesForDateProvider(_selectedDate)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retryDatabase),
                ),
              ),
          data:
              (items) =>
                  items.isEmpty
                      ? EmptyState(
                        icon: Icons.event_available_outlined,
                        title: l10n.noDosesForDate,
                        message: l10n.doseHistoryNote,
                      )
                      : Column(
                        children: items
                            .map(
                              (dose) =>
                                  _DoseCard(dose: dose, onStatus: _setStatus),
                            )
                            .toList(growable: false),
                      ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.doseHistoryNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _setStatus(DoseRecord dose, DoseStatus status) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(doseRepositoryProvider).setStatus(dose.id, status);
      await ref
          .read(notificationServiceProvider)
          .cancel(postponedNotificationIdBase + dose.id);
      ref.invalidate(dosesForDateProvider(_selectedDate));
      ref.invalidate(adherenceSummaryProvider(_range));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.doseStatusSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.medicationLoadError)));
      }
    }
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.summary, required this.monthly});
  final AsyncValue<AdherenceSummary> summary;
  final bool monthly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: summary.when(
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (_, _) => Text(l10n.medicationLoadError),
          data: (value) {
            if (value.total == 0) return Text(l10n.noDueDoses);
            final rate = value.rate!;
            return Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: rate),
                      Center(
                        child: Text(
                          '${(rate * 100).round()}%',
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.adherence, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${value.taken} / ${value.total} · ${l10n.adherenceRate}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.skipped}: ${value.skipped} · ${l10n.localeName.startsWith('ar') ? 'مؤجلة' : 'Postponed'}: ${value.postponed} · ${l10n.localeName.startsWith('ar') ? 'غير مؤكدة' : 'Unconfirmed'}: ${value.unconfirmed}',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DoseCard extends ConsumerWidget {
  const _DoseCard({required this.dose, required this.onStatus});
  final DoseRecord dose;
  final Future<void> Function(DoseRecord, DoseStatus) onStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final due = dose.scheduledAtUtc <= now;
    final late =
        (dose.status == DoseStatus.pending ||
            dose.status == DoseStatus.postponed) &&
        due;
    final isArabic = l10n.localeName.startsWith('ar');
    final (label, icon, color) = switch (dose.status) {
      DoseStatus.taken => (
        l10n.taken,
        Icons.check_circle_rounded,
        AppColors.success(Theme.of(context).brightness),
      ),
      DoseStatus.skipped => (
        l10n.skipped,
        Icons.do_not_disturb_on_rounded,
        AppColors.warning(Theme.of(context).brightness),
      ),
      DoseStatus.postponed => (
        isArabic ? 'مؤجلة' : 'Postponed',
        Icons.snooze_rounded,
        AppColors.warning(Theme.of(context).brightness),
      ),
      DoseStatus.unconfirmed => (
        isArabic ? 'غير مؤكدة' : 'Unconfirmed',
        Icons.help_outline_rounded,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      DoseStatus.missed => (
        isArabic ? 'غير مؤكدة' : 'Unconfirmed',
        Icons.help_outline_rounded,
        Theme.of(context).colorScheme.error,
      ),
      DoseStatus.pending => (
        late ? l10n.overdue : l10n.pending,
        late ? Icons.schedule_rounded : Icons.notifications_none_rounded,
        Theme.of(context).colorScheme.primary,
      ),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            DoseSummary(
              name: dose.medicationName,
              description:
                  '${dose.dosageAmount} ${dose.dosageUnit} \u00b7 $label',
              time: DateFormat.jm(l10n.localeName).format(dose.scheduledAt),
              icon: icon,
              color: color,
            ),
            const SizedBox(height: 8),
            _DoseMetadata(
              label: isArabic ? 'وقت الجدولة' : 'Scheduled',
              value: DateFormat.jm(l10n.localeName).format(dose.scheduledAt),
            ),
            if (dose.statusRecordedAtUtc != null)
              _DoseMetadata(
                label: isArabic ? 'سُجلت الحالة' : 'Status recorded',
                value: DateFormat.jm(l10n.localeName).format(
                  DateTime.fromMillisecondsSinceEpoch(
                    dose.statusRecordedAtUtc!,
                    isUtc: true,
                  ).toLocal(),
                ),
              ),
            if (dose.takenAtUtc != null)
              _DoseMetadata(
                label: isArabic ? 'وقت التناول' : 'Taken at',
                value: DateFormat.jm(l10n.localeName).format(
                  DateTime.fromMillisecondsSinceEpoch(
                    dose.takenAtUtc!,
                    isUtc: true,
                  ).toLocal(),
                ),
              ),
            if (dose.postponedUntilUtc != null)
              _DoseMetadata(
                label: isArabic ? 'التذكير الجديد' : 'New reminder',
                value: DateFormat.jm(l10n.localeName).format(
                  DateTime.fromMillisecondsSinceEpoch(
                    dose.postponedUntilUtc!,
                    isUtc: true,
                  ).toLocal(),
                ),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                isArabic ? 'سجل تغييرات الحالة' : 'Status history',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              children: [
                FutureBuilder<List<Map<String, Object?>>>(
                  future: ref
                      .read(doseRepositoryProvider)
                      .eventsForDose(dose.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      );
                    }
                    return Column(
                      children: snapshot.data!
                          .map((event) {
                            final recorded =
                                DateTime.fromMillisecondsSinceEpoch(
                                  event['recorded_at_utc']! as int,
                                  isUtc: true,
                                ).toLocal();
                            final status = event['new_status']! as String;
                            final until = event['postponed_until_utc'] as int?;
                            final label = _statusName(status, isArabic);
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.history_rounded,
                                size: 18,
                              ),
                              title: Text(
                                '${DateFormat.jm(l10n.localeName).format(recorded)} · $label',
                              ),
                              subtitle:
                                  until == null
                                      ? null
                                      : Text(
                                        '${isArabic ? 'أُجل التذكير إلى' : 'Reminder moved to'} ${DateFormat.jm(l10n.localeName).format(DateTime.fromMillisecondsSinceEpoch(until, isUtc: true).toLocal())}',
                                      ),
                            );
                          })
                          .toList(growable: false),
                    );
                  },
                ),
              ],
            ),
            if (due)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (dose.status != DoseStatus.taken)
                    FilledButton.tonalIcon(
                      onPressed: () => onStatus(dose, DoseStatus.taken),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.markTaken),
                    ),
                  if (dose.status != DoseStatus.skipped)
                    OutlinedButton.icon(
                      onPressed: () => onStatus(dose, DoseStatus.skipped),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      label: Text(l10n.markSkipped),
                    ),
                  if (dose.status != DoseStatus.pending)
                    TextButton(
                      onPressed: () => onStatus(dose, DoseStatus.pending),
                      child: Text(l10n.undoConfirmation),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DoseMetadata extends StatelessWidget {
  const _DoseMetadata({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 4),
    child: Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

String _statusName(String value, bool arabic) => switch (value) {
  'pending' => arabic ? 'بانتظار التأكيد' : 'Pending',
  'taken' => arabic ? 'تم التناول' : 'Taken',
  'postponed' => arabic ? 'مؤجلة' : 'Postponed',
  'skipped' => arabic ? 'تم التخطي' : 'Skipped',
  'unconfirmed' || 'missed' => arabic ? 'غير مؤكدة' : 'Unconfirmed',
  _ => value,
};
