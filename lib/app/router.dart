import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/doses/screens/history_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/medicines/screens/medicines_screen.dart';
import '../features/medicines/screens/medication_details_screen.dart';
import '../features/medicines/screens/medication_form_screen.dart';
import '../features/medicines/screens/care_recipients_management_screen.dart';
import '../features/medicines/providers/medications_provider.dart';
import '../features/medicines/models/medication.dart';
import '../core/notifications/notification_scheduler.dart';
import '../core/notifications/notification_service.dart';
import '../features/settings/screens/information_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/app_shell.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/page_content.dart';
import '../features/medicines/screens/medication_alarm_screen.dart';
import '../features/measurements/screens/measurements_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medications',
                builder: (context, state) => const MedicinesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const MedicationFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder:
                        (context, state) => MedicationDetailsScreen(
                          id: int.parse(state.pathParameters['id']!),
                        ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          final medications =
                              ref.read(medicationsProvider).asData?.value ??
                              const [];
                          Medication? selected;
                          for (final item in medications) {
                            if (item.id == id) {
                              selected = item;
                              break;
                            }
                          }
                          return MedicationFormScreen(medication: selected);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/measurements',
                builder:
                    (context, state) => const MeasurementsDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/alarm/:id',
        builder:
            (context, state) => MedicationAlarmScreen(
              medicationId: int.parse(state.pathParameters['id']!),
              notificationId: int.tryParse(
                state.uri.queryParameters['notificationId'] ?? '',
              ),
              closeActivityOnDismiss:
                  state.uri.queryParameters['closeActivityOnDismiss'] == 'true',
            ),
      ),
      GoRoute(
        path: '/care-recipients',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CareRecipientsManagementScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const InformationScreen(isPrivacy: true),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const InformationScreen(isPrivacy: false),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: PageContent(
          children: [
            EmptyState(
              icon: Icons.explore_off_outlined,
              title: l10n.pageNotFound,
              message: l10n.backHome,
              action: FilledButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.backHome),
              ),
            ),
          ],
        ),
      );
    },
  );
  final notifications = ref.read(notificationServiceProvider);
  notifications.onMedicationTap = (
    medicationId,
    notificationId,
    launchedApplication,
  ) {
    unawaited(
      _openMedicationAlarm(
        router: router,
        notifications: notifications,
        medicationId: medicationId,
        notificationId: notificationId,
        launchedApplication: launchedApplication,
      ),
    );
  };
  ref.onDispose(router.dispose);
  ref.onDispose(() => notifications.onMedicationTap = null);
  return router;
});

Future<void> _openMedicationAlarm({
  required GoRouter router,
  required NotificationService notifications,
  required int medicationId,
  required int? notificationId,
  required bool launchedApplication,
}) async {
  final closeActivity =
      launchedApplication || await notifications.shouldCloseActivityForAlarm();
  final query = <String, String>{
    if (notificationId != null) 'notificationId': '$notificationId',
    if (closeActivity) 'closeActivityOnDismiss': 'true',
  };
  final location =
      Uri(
        path: '/alarm/$medicationId',
        queryParameters: query.isEmpty ? null : query,
      ).toString();
  if (closeActivity) {
    // Cold starts and notifications that brought a background Activity up
    // should finish that Android Activity when dismissed.
    router.go(location);
  } else {
    // The user was already in Dawaei; preserve the current route under alarm.
    router.push(location);
  }
}
