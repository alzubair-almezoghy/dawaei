import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'medication_reason_screen.dart';

enum _FrequencyChoice { onceDaily, twiceDaily, asNeeded, moreOptions }

class MedicationFrequencyScreen extends StatefulWidget {
  const MedicationFrequencyScreen({
    required this.recipientId,
    required this.recipientName,
    super.key,
  });

  final int? recipientId;
  final String? recipientName;

  @override
  State<MedicationFrequencyScreen> createState() =>
      _MedicationFrequencyScreenState();
}

class _MedicationFrequencyScreenState extends State<MedicationFrequencyScreen> {
  _FrequencyChoice? _selected;
  bool _openingForm = false;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _label(_FrequencyChoice choice) {
    if (_isArabic) {
      return switch (choice) {
        _FrequencyChoice.onceDaily => '\u0645\u0631\u0629\u0020\u0648\u0627\u062d\u062f\u0629\u0020\u0641\u064a\u0020\u0627\u0644\u064a\u0648\u0645',
        _FrequencyChoice.twiceDaily => '\u0645\u0631\u062a\u064a\u0646\u0020\u0641\u064a\u0020\u0627\u0644\u064a\u0648\u0645',
        _FrequencyChoice.asNeeded => '\u062d\u0633\u0628\u0020\u0627\u0644\u062d\u0627\u062c\u0629\u0020\u0028\u0644\u0627\u0020\u062a\u0630\u0643\u064a\u0631\u0029',
        _FrequencyChoice.moreOptions => '\u0623\u062d\u062a\u0627\u062c\u0020\u0627\u0644\u0645\u0632\u064a\u062f\u0020\u0645\u0646\u0020\u0627\u0644\u062e\u064a\u0627\u0631\u0627\u062a\u002e\u002e\u002e',
      };
    }
    return switch (choice) {
      _FrequencyChoice.onceDaily => 'Once a day',
      _FrequencyChoice.twiceDaily => 'Twice a day',
      _FrequencyChoice.asNeeded => 'As needed (no reminder)',
      _FrequencyChoice.moreOptions => 'I need more options...',
    };
  }

  Future<void> _continue() async {
    final choice = _selected;
    if (choice == null || _openingForm) return;
    setState(() => _openingForm = true);
    final scheduleCount = switch (choice) {
      _FrequencyChoice.onceDaily => 1,
      _FrequencyChoice.twiceDaily => 2,
      _FrequencyChoice.asNeeded => 0,
      _FrequencyChoice.moreOptions => 1,
    };
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (_) => MedicationReasonScreen(
                recipientId: widget.recipientId,
                recipientName: widget.recipientName,
                initialScheduleCount: scheduleCount,
                allowNoSchedule: choice == _FrequencyChoice.asNeeded,
              ),
        ),
      );
      if (saved == true && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _openingForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final accent = AppColors.accentFor(brightness);
    final primaryText = AppColors.primaryText(brightness);
    const choices = _FrequencyChoice.values;

    return Scaffold(
      backgroundColor: AppColors.pageBackground(brightness),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF071F2D), Color(0xFF10384B), Color(0xFF071F2D)]
                : const [Colors.white, Color(0xFFF0F8FA), Colors.white],
            stops: [0, .48, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 18, top: 8),
                  child: IconButton.filledTonal(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(false),
                    style: IconButton.styleFrom(
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: .08)
                          : AppColors.brand.withValues(alpha: .08),
                      foregroundColor: primaryText,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22, compact ? 4 : 12, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: compact ? 82 : 96,
                          height: compact ? 82 : 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand.withValues(alpha: .18),
                            border: Border.all(
                              color: accent.withValues(alpha: .28),
                            ),
                          ),
                          child: Icon(
                            Icons.medication_rounded,
                            size: compact ? 42 : 48,
                            color: accent,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 22 : 34),
                      Text(
                        _isArabic ? '\u062f\u0648\u0627\u0621 \u062c\u062f\u064a\u062f' : 'NEW MEDICATION',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: accent,
                          letterSpacing: _isArabic ? 0 : 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isArabic
                            ? '\u0643\u0645 \u0645\u0631\u0629 \u062a\u062a\u0646\u0627\u0648\u0644 \u0647\u0630\u0627 \u0627\u0644\u062f\u0648\u0627\u0621\u061f'
                            : 'How often do you take this medication?',
                        textAlign: TextAlign.end,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: compact ? 22 : 32),
                      ...choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FrequencyTile(
                            title: _label(choice),
                            selected: _selected == choice,
                            accent: accent,
                            onTap: () => setState(() => _selected = choice),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed:
                            _selected == null || _openingForm
                                ? null
                                : _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: dark ? AppColors.darkBackground : Colors.white,
                          disabledBackgroundColor: accent.withValues(alpha: .3),
                          shape: const StadiumBorder(),
                        ),
                        child:
                            _openingForm
                                ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  l10n.onboardingNext,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: .56,
                        minHeight: 4,
                        backgroundColor: dark
                            ? Colors.white.withValues(alpha: .12)
                            : const Color(0xFFDCE9ED),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyTile extends StatelessWidget {
  const _FrequencyTile({
    required this.title,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surfaceContainerLow;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: .12) : surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? accent
                  : (dark
                      ? Colors.white.withValues(alpha: .06)
                      : theme.colorScheme.outlineVariant),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? accent
                        : (dark ? Colors.white38 : theme.colorScheme.outline),
                    width: selected ? 2 : 1.8,
                  ),
                ),
                child:
                    selected
                        ? Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                          ),
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
