import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: dark ? AppColors.navigation : Colors.white,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor:
          dark ? AppColors.navigation : Colors.white,
    );
    final labels = [
      l10n.home,
      l10n.medications,
      l10n.history,
      isArabic ? 'القياسات' : 'Measurements',
      l10n.settings,
    ];
    const icons = [
      Icons.home_outlined,
      Icons.medication_outlined,
      Icons.calendar_month_outlined,
      Icons.monitor_heart_outlined,
      Icons.tune_rounded,
    ];
    const selected = [
      Icons.home_rounded,
      Icons.medication_rounded,
      Icons.calendar_month_rounded,
      Icons.monitor_heart_rounded,
      Icons.tune_rounded,
    ];
    void navigate(int index) => navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradientFor(brightness),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.primaryText(brightness),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: systemUiStyle,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.spa_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.appTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(brightness),
                  ),
                ),
              ],
            ),
          ),
          body: navigationShell,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: dark ? AppColors.navigation : Colors.white,
              border: Border(
                top: BorderSide(
                  color:
                      dark
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppColors.subtleBorder(brightness),
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigate,
              labelBehavior:
                  MediaQuery.textScalerOf(context).scale(14) > 22
                      ? NavigationDestinationLabelBehavior.alwaysHide
                      : NavigationDestinationLabelBehavior.alwaysShow,
              destinations: List.generate(
                labels.length,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  selectedIcon: Icon(selected[i]),
                  label: labels[i],
                ),
              ),
            ),
          ),
          floatingActionButton:
              navigationShell.currentIndex <= 1
                  ? FloatingActionButton.extended(
                    onPressed: () => context.push('/medications/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addMedication),
                  )
                  : null,
        ),
      ),
    );
  }
}
