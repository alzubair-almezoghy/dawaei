import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/page_content.dart';
import '../models/medication.dart';
import '../providers/medications_provider.dart';

class MedicationDetailsScreen extends ConsumerWidget {
  const MedicationDetailsScreen({required this.id, super.key});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(medicationsProvider);
    final medication = list.asData?.value.where((m) => m.id == id).firstOrNull;
    return Scaffold(
      backgroundColor: AppColors.pageBackground(Theme.of(context).brightness),
      appBar: AppBar(
        title: Text(l10n.medicineDetails),
        actions: [
          if (medication != null)
            IconButton(
              tooltip: l10n.editMedication,
              onPressed: () => context.push('/medications/$id/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body:
          list.isLoading
              ? const Center(child: CircularProgressIndicator())
              : medication == null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.medicationLoadError),
                ),
              )
              : _DetailsBody(medication: medication),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.medication});
  final Medication medication;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PageContent(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medication_rounded,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        medication.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${medication.dosageAmount} ${medication.dosageUnit}${medication.form == null ? '' : ' · ${medication.form}'}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Chip(
                  label: Text(medication.isActive ? l10n.active : l10n.paused),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: l10n.scheduleLabel,
          icon: Icons.schedule_rounded,
          child: Column(
            children: [
              if (medication.schedules.isEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: Text(l10n.noReminder),
                )
              else
                ...medication.schedules.map(
                  (schedule) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm_outlined),
                    title: Text(schedule.timeOfDay),
                    subtitle: Text(
                      schedule.type == MedicationScheduleType.daily
                          ? l10n.scheduleDailySummary
                          : _days(l10n, schedule.weekdays),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: l10n.dateRange(
            _date(context, medication.startDate),
            medication.endDate == null
                ? l10n.noEndDateValue
                : _date(context, medication.endDate!),
          ),
          icon: Icons.calendar_month_outlined,
          child: const SizedBox.shrink(),
        ),
        if (medication.indication?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: Localizations.localeOf(context).languageCode == 'ar'
                ? '\u0627\u0644\u062d\u0627\u0644\u0629 \u0627\u0644\u0645\u0631\u0636\u064a\u0629'
                : 'Medical condition',
            icon: Icons.medical_information_outlined,
            child: Text(medication.indication!),
          ),
        ],
        if (medication.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: l10n.instructions,
            icon: Icons.notes_rounded,
            child: Text(medication.notes!),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            try {
              await ref
                  .read(medicationsProvider.notifier)
                  .setActive(medication.id!, !medication.isActive);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      medication.isActive
                          ? l10n.medicationPaused
                          : l10n.medicationResumed,
                    ),
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.medicationLoadError)),
                );
              }
            }
          },
          icon: Icon(
            medication.isActive
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
          label: Text(
            medication.isActive ? l10n.pauseMedication : l10n.resumeMedication,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _archive(context, ref, medication, l10n),
          icon: const Icon(Icons.archive_outlined),
          label: Text(l10n.archiveMedication),
        ),
      ],
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.archiveConfirmationTitle),
            content: Text(l10n.archiveConfirmationBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.archiveMedication),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(medicationsProvider.notifier).archive(medication.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.medicationArchived)));
        context.pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.medicationLoadError)));
      }
    }
  }

  String _date(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);
  String _days(AppLocalizations l, Set<int> days) => [
    if (days.contains(1)) l.monday,
    if (days.contains(2)) l.tuesday,
    if (days.contains(3)) l.wednesday,
    if (days.contains(4)) l.thursday,
    if (days.contains(5)) l.friday,
    if (days.contains(6)) l.saturday,
    if (days.contains(7)) l.sunday,
  ].join('، ');
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (child is! SizedBox) ...[const SizedBox(height: 10), child],
        ],
      ),
    ),
  );
}
