import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:dawaei/features/medicines/models/medication.dart';
import 'package:dawaei/features/medicines/screens/medication_form_screen.dart';
import 'package:dawaei/features/settings/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'app_test.dart' as app_test;
import 'support/memory_settings_store.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    timezone_data.initializeTimeZones();
    final loader = FontLoader('IBM Plex Sans Arabic');
    for (final weight in ['Regular', 'Medium', 'SemiBold']) {
      loader.addFont(
        rootBundle.load('assets/fonts/IBMPlexSansArabic-$weight.ttf'),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final locale in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('$locale ${dark ? 'dark' : 'light'} visual review', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await app_test.startApp(
          tester,
          MemorySettingsStore(
            AppSettings(
              languageCode: locale,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          medications: [
            Medication(
              id: 7,
              name: locale == 'ar' ? 'فيتامين د' : 'Vitamin D',
              dosageAmount: '1',
              dosageUnit: 'tablet',
              startDate: DateTime.now(),
              schedules: [
                MedicationSchedule(
                  type: MedicationScheduleType.daily,
                  timeOfDay: '23:59',
                ),
              ],
            ),
          ],
        );
        final suffix = '${locale}_${dark ? 'dark' : 'light'}';
        await capture(tester, 'home_$suffix');
        for (final entry
            in {1: 'medications', 2: 'history', 3: 'settings'}.entries) {
          await tester.tap(find.byType(NavigationDestination).at(entry.key));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capture(tester, '${entry.value}_$suffix');
        }
        await tester.tap(find.byType(NavigationDestination).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await capture(tester, 'form_$suffix');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  for (final locale in ['ar', 'en']) {
    testWidgets('$locale form fits 320dp with doubled text', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await app_test.startApp(
        tester,
        MemorySettingsStore(AppSettings(languageCode: locale)),
        textScale: 2,
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(MedicationFormScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      final scroll =
          find
              .descendant(
                of: find.byType(MedicationFormScreen),
                matching: find.byType(Scrollable),
              )
              .first;
      for (var i = 0; i < 9; i++) {
        await tester.drag(scroll, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('app-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/design-review')
      ..createSync(recursive: true);
    File(
      '${directory.path}/$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}
