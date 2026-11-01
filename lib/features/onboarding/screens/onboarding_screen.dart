import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../measurements/screens/measurements_setup_screen.dart';
import '../../medicines/providers/medications_provider.dart';
import '../../medicines/screens/medication_recipient_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function({required Set<String> selectedCategories})
  onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;
  bool _medicationsComplete = false;
  bool _measurementsComplete = false;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(_refreshSetupProgress());
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing || !_medicationsComplete || !_measurementsComplete) return;
    setState(() => _finishing = true);
    try {
      await widget.onComplete(
        selectedCategories: const {'medications', 'measurements'},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsSaveError)),
      );
    }
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _refreshSetupProgress() async {
    var medicationsComplete = false;
    try {
      medicationsComplete =
          (await ref.read(medicationsProvider.future)).isNotEmpty;
    } catch (_) {
      medicationsComplete = false;
    }
    final readings =
        await SharedPreferencesAsync().getStringList(measurementsStorageKey) ??
        [];
    if (!mounted) return;
    setState(() {
      _medicationsComplete = medicationsComplete;
      _measurementsComplete = readings.isNotEmpty;
    });
  }

  Future<void> _openMedications() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MedicationRecipientScreen()),
    );
    await _refreshSetupProgress();
  }

  Future<void> _openMeasurements() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MeasurementsSetupScreen()),
    );
    await _refreshSetupProgress();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pages = [
      _OnboardingPage(
        image: 'assets/onboarding/reminders.png',
        title: l10n.onboardingRemindersTitle,
        body: l10n.onboardingRemindersBody,
      ),
      _OnboardingPage(
        image: 'assets/onboarding/track.png',
        title: l10n.onboardingTrackTitle,
        body: l10n.onboardingTrackBody,
      ),
    ];
    final compact = MediaQuery.sizeOf(context).height < 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _page == 2 ? Brightness.light : Brightness.dark,
        statusBarBrightness: _page == 2 ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: 3,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                return Image.asset(
                  index == 2
                      ? 'assets/onboarding/setup_background.png'
                      : pages[index].image,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder:
                      (context, error, stackTrace) => ColoredBox(
                        color: theme.colorScheme.primaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.medication_rounded,
                            size: 120,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                );
              },
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.34, 0.52, 0.72, 1],
                      colors: [
                        Colors.transparent,
                        Color(0x10101C1A),
                        Color(0x66101C1A),
                        Color(0xE6101C1A),
                        AppColors.darkBackground,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  compact ? 4 : 10,
                  24,
                  compact ? 10 : 16,
                ),
                child:
                    _page == 2
                        ? _buildRoutinePage(l10n, compact)
                        : _buildIntroPage(l10n, theme, pages, compact),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkip(AppLocalizations l10n) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: TextButton(
      onPressed:
          _finishing
              ? null
              : () => _controller.animateToPage(
                2,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
              ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      ),
      child: Text(l10n.onboardingSkip),
    ),
  );

  Widget _buildIndicators() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      3,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: index == _page ? 24 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: index == _page ? 1 : 0.48),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  Widget _buildIntroPage(
    AppLocalizations l10n,
    ThemeData theme,
    List<_OnboardingPage> pages,
    bool compact,
  ) {
    return Column(
      children: [
        _buildSkip(l10n),
        Expanded(flex: compact ? 3 : 6, child: const SizedBox()),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Column(
            key: ValueKey(_page),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pages[_page].title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 16),
                  ],
                ),
              ),
              SizedBox(height: compact ? 8 : 14),
              Text(
                pages[_page].body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.55,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(flex: compact ? 1 : 2, child: const SizedBox()),
        _buildIndicators(),
        SizedBox(height: compact ? 14 : 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _finishing ? null : _next,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brand,
              padding: EdgeInsets.symmetric(vertical: compact ? 14 : 18),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.onboardingNext),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutinePage(AppLocalizations l10n, bool compact) {
    final completedCount =
        (_medicationsComplete ? 1 : 0) + (_measurementsComplete ? 1 : 0);
    final progress = completedCount / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: compact ? 18 : 34),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 17,
                      color: Color(0xFF8AF0CB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onboardingFinalStepLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completedCount / 2',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFF9BE8D1),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 18 : 26),
                Text(
                  l10n.onboardingRoutineTitle,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    shadows: const [
                      Shadow(color: Color(0x66000000), blurRadius: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onboardingRoutineBody,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: .82),
                    height: 1.55,
                  ),
                ),
                SizedBox(height: compact ? 22 : 32),
                Row(
                  children: [
                    Text(
                      l10n.onboardingSetupProgress,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completedCount/2',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder:
                        (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF8AF0CB),
                          ),
                        ),
                  ),
                ),
                SizedBox(height: compact ? 18 : 24),
                _SetupOption(
                  title: l10n.onboardingCategoryMedications,
                  body: l10n.onboardingCategoryMedicationsBody,
                  icon: Icons.medication_outlined,
                  completed: _medicationsComplete,
                  onTap: _openMedications,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 28),
                  child: Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                _SetupOption(
                  title: l10n.onboardingCategoryMeasurements,
                  body: l10n.onboardingCategoryMeasurementsBody,
                  icon: Icons.monitor_heart_outlined,
                  completed: _measurementsComplete,
                  onTap: _openMeasurements,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _finishing || !_medicationsComplete || !_measurementsComplete
                    ? null
                    : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF7FBFA),
              disabledBackgroundColor: const Color(0xFF374249),
              foregroundColor: const Color(0xFF0E5660),
              disabledForegroundColor: Colors.white.withValues(alpha: .48),
              padding: EdgeInsets.symmetric(vertical: compact ? 14 : 17),
              shape: const StadiumBorder(),
              elevation: _medicationsComplete && _measurementsComplete ? 3 : 0,
            ),
            child:
                _finishing
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(l10n.onboardingStart),
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        _buildIndicators(),
      ],
    );
  }
}

class _SetupOption extends StatelessWidget {
  const _SetupOption({
    required this.title,
    required this.body,
    required this.icon,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFF8AF0CB).withValues(alpha: .08),
        highlightColor: Colors.white.withValues(alpha: .025),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: MediaQuery.sizeOf(context).height < 700 ? 13 : 17,
          ),
          decoration: BoxDecoration(
            color:
                completed ? const Color(0xAA10382F) : const Color(0xB30D1820),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  completed
                      ? const Color(0x568AF0CB)
                      : Colors.white.withValues(alpha: .10),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      completed
                          ? const Color(0x268AF0CB)
                          : const Color(0x1FFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                      completed
                          ? const Color(0xFF8AF0CB)
                          : const Color(0xFFEAF5F5),
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .72),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                child:
                    completed
                        ? const _CompletionMark(key: ValueKey('complete'))
                        : _OpenMark(
                          key: const ValueKey('open'),
                          direction: direction,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionMark extends StatelessWidget {
  const _CompletionMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 29,
    height: 29,
    decoration: const BoxDecoration(
      color: Color(0xFF75E9C2),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.check_rounded, color: Color(0xFF12362F), size: 19),
  );
}

class _OpenMark extends StatelessWidget {
  const _OpenMark({required this.direction, super.key});
  final TextDirection direction;

  @override
  Widget build(BuildContext context) => Container(
    width: 29,
    height: 29,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withValues(alpha: .35)),
      shape: BoxShape.circle,
    ),
    child: Icon(
      direction == TextDirection.rtl
          ? Icons.chevron_left_rounded
          : Icons.chevron_right_rounded,
      color: Colors.white.withValues(alpha: .78),
      size: 21,
    ),
  );
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.body,
  });
  final String image;
  final String title;
  final String body;
}
