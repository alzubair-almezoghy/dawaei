import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/database_providers.dart';
import '../core/notifications/notification_scheduler.dart';
import '../core/notifications/notification_service.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/settings/providers/settings_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'widgets/dawaei_splash_animation.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

const _onboardingCompletedKey = 'dawaei.onboarding.completed.v2';
const _onboardingCategoriesKey = 'dawaei.onboarding.categories.v1';
const _startupTimeout = Duration(seconds: 20);
const _startupChannel = MethodChannel('app.dawaei.dawaei/startup');

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final preferences = SharedPreferencesAsync();
  return await preferences.getBool(_onboardingCompletedKey) ?? false;
});

/// Settings, onboarding state, and the local database are required before the
/// first app route is shown. Notification setup runs independently so a plugin
/// delay cannot hold the UI on the Android launch window.
final appStartupProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(settingsProvider.future);
  final onboarding = ref.watch(onboardingCompletedProvider.future);
  final database = ref.watch(appDatabaseProvider).database;
  await Future.wait<dynamic>([
    settings,
    onboarding,
    database,
  ]).timeout(_startupTimeout);
});

final alarmStartupProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(settingsProvider.future);
  final onboarding = ref.watch(onboardingCompletedProvider.future);
  await Future.wait<dynamic>([
    settings,
    onboarding,
  ]).timeout(const Duration(seconds: 12));
});

class DawaeiApp extends ConsumerStatefulWidget {
  const DawaeiApp({super.key});

  @override
  ConsumerState<DawaeiApp> createState() => _DawaeiAppState();
}

class _DawaeiAppState extends ConsumerState<DawaeiApp> {
  Timer? _splashTimer;
  ValueNotifier<bool>? _pendingAlarmNotifier;
  Duration _splashRemaining = const Duration(seconds: 5);
  bool _splashElapsed = false;
  bool _skipSplash = false;

  @override
  void initState() {
    super.initState();
    unawaited(_enableEdgeToEdge());
    _scheduleSplashEnd(const Duration(seconds: 5));
    unawaited(_syncNativeSplashDuration());

    final notifications = ref.read(notificationServiceProvider);
    _pendingAlarmNotifier = notifications.hasPendingMedicationAlarm;
    _pendingAlarmNotifier!.addListener(_onPendingMedicationAlarm);
    if (_pendingAlarmNotifier!.value) _onPendingMedicationAlarm();
    unawaited(_initializeNotifications(notifications));
  }

  Future<void> _enableEdgeToEdge() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // Keep startup usable if a platform does not support edge-to-edge mode.
    }
  }

  void _scheduleSplashEnd(Duration remaining) {
    _splashTimer?.cancel();
    if (remaining <= Duration.zero) {
      _splashElapsed = true;
      return;
    }
    _splashTimer = Timer(remaining, () {
      if (mounted) setState(() => _splashElapsed = true);
    });
  }

  Future<void> _syncNativeSplashDuration() async {
    try {
      final remainingMilliseconds = await _startupChannel.invokeMethod<int>(
        'getSplashRemainingMillis',
      );
      if (!mounted || _skipSplash || _splashElapsed) return;
      if (remainingMilliseconds != null) {
        final remaining = Duration(milliseconds: remainingMilliseconds);
        _splashRemaining = remaining;
        _scheduleSplashEnd(remaining);
        if (mounted) setState(() {});
      }
    } on PlatformException {
      // Use the five-second Flutter fallback if native timing is unavailable.
    } on MissingPluginException {
      // Widget tests and non-Android targets use the same fallback timer.
    }
  }

  Future<void> _initializeNotifications(
    NotificationService notifications,
  ) async {
    try {
      await notifications.initialize().timeout(const Duration(seconds: 12));
      await notifications.refreshDeviceTimezone().timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // Keep startup available. The scheduler can retry and Settings exposes
      // notification permissions and status to the user.
    }
    if (mounted && notifications.hasPendingMedicationAlarm.value) {
      _onPendingMedicationAlarm();
    }
  }

  void _onPendingMedicationAlarm() {
    if (_skipSplash || _pendingAlarmNotifier?.value != true) return;
    _splashTimer?.cancel();
    setState(() => _skipSplash = true);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _pendingAlarmNotifier?.removeListener(_onPendingMedicationAlarm);
    super.dispose();
  }

  void _retryStartup() {
    ref.invalidate(settingsProvider);
    ref.invalidate(onboardingCompletedProvider);
    ref.invalidate(appStartupProvider);
    ref.invalidate(alarmStartupProvider);
  }

  Widget _switcher(Widget child) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 380),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder:
        (child, animation) => FadeTransition(opacity: animation, child: child),
    child: child,
  );

  Widget _readyApp() {
    final settings = ref.watch(settingsProvider).requireValue;
    final completed = ref.watch(onboardingCompletedProvider).requireValue;
    if (!completed) {
      return KeyedSubtree(
        key: const ValueKey('ready-app'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: OnboardingScreen(
            onComplete: ({required selectedCategories}) async {
              final preferences = SharedPreferencesAsync();
              await preferences.setStringList(
                _onboardingCategoriesKey,
                selectedCategories.toList(),
              );
              await preferences.setBool(_onboardingCompletedKey, true);
              ref.invalidate(onboardingCompletedProvider);
            },
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('ready-app'),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startup =
        _skipSplash
            ? ref.watch(alarmStartupProvider)
            : ref.watch(appStartupProvider);
    if (!_splashElapsed && !_skipSplash) {
      return _switcher(
        _BrandedSplash(
          duration: _splashRemaining,
          key: const ValueKey('brand-splash'),
        ),
      );
    }
    return startup.when(
      data: (_) => _switcher(_readyApp()),
      loading:
          () => _switcher(const _StartupApp(key: ValueKey('startup-loading'))),
      error:
          (error, stack) => _switcher(
            _StartupApp(
              key: const ValueKey('startup-error'),
              onRetry: _retryStartup,
            ),
          ),
    );
  }
}

class _BrandedSplash extends StatelessWidget {
  const _BrandedSplash({required this.duration, super.key});

  final Duration duration;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    themeMode: ThemeMode.dark,
    home: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.darkBackground,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF071F2D),
        body: DawaeiSplashAnimation(duration: duration),
      ),
    ),
  );
}

class _StartupApp extends StatelessWidget {
  const _StartupApp({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRetry == null) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(l10n.loading),
                    ] else ...[
                      Text(
                        l10n.startupError,
                        key: const Key('startup-error-message'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('startup-retry'),
                        onPressed: onRetry,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
