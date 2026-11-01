import 'package:flutter/material.dart';
import '../../../app/theme/app_geometry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_content.dart';
import '../models/medication.dart';
import '../providers/medications_provider.dart';
import 'medication_form_screen.dart';

class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({this.onboardingMode = false, super.key});
  final bool onboardingMode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final medicines = ref.watch(medicationsProvider);
    final page = PageContent(
      storageKey: 'medicines',
      backgroundGradient: onboardingMode,
      children: [
        PageHeading(
          title: l10n.medicationsTitle,
          subtitle: l10n.medicationsSubtitle,
        ),
        medicines.when(
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
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
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryDatabase),
                ),
              ),
          data:
              (items) =>
                  items.isEmpty
                      ? EmptyState(
                        icon: Icons.medication_outlined,
                        title: l10n.noMedicationsTitle,
                        message: l10n.emptyMedicationsDescription,
                        action: FilledButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.emptyMedicationsAction),
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...items.map(
                            (item) => _MedicationCard(
                              medication: item,
                              onboardingMode: onboardingMode,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => _openForm(context),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addMedication),
                          ),
                        ],
                      ),
        ),
      ],
    );
    if (!onboardingMode) return page;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationsTitle),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.done),
          ),
        ],
      ),
      body: page,
    );
  }

  void _openForm(BuildContext context) {
    if (onboardingMode) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MedicationFormScreen(onboardingMode: true),
        ),
      );
    } else {
      context.push('/medications/new');
    }
  }
}

class _MedicationCard extends ConsumerWidget {
  const _MedicationCard({
    required this.medication,
    this.onboardingMode = false,
  });
  final Medication medication;
  final bool onboardingMode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color =
        medication.colorValue == null
            ? theme.colorScheme.primary
            : Color(medication.colorValue!);
    final schedule =
        medication.schedules.isEmpty
            ? l10n.noReminder
            : medication.schedules.map((s) => s.timeOfDay).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap:
            onboardingMode
                ? null
                : () => context.push('/medications/${medication.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: AppRadius.input,
                ),
                child: Icon(Icons.medication_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.dosageAmount} ${medication.dosageUnit}${medication.form == null ? '' : ' · ${medication.form}'}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      schedule,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        medication.isActive ? l10n.active : l10n.paused,
                      ),
                      avatar: Icon(
                        medication.isActive
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
