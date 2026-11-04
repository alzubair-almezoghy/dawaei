import 'package:dawaei/shared/widgets/postpone_duration_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'postpone options remain reachable on a compact screen with keyboard and large text',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 480)
        ..devicePixelRatio = 1
        ..viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.8)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: FilledButton(
                      onPressed: () async {
                        final choice = await showPostponeDurationSheet(
                          context: context,
                          title:
                              '\u062a\u0623\u062c\u064a\u0644 \u062a\u0630\u0643\u064a\u0631 \u0627\u0644\u062c\u0631\u0639\u0629',
                          minuteOptions: const [5, 10, 15, 30],
                          minuteLabelBuilder:
                              (minutes) =>
                                  '\u0628\u0639\u062f $minutes \u062f\u0642\u064a\u0642\u0629',
                          customLabel:
                              '\u0648\u0642\u062a \u0645\u062e\u0635\u0635',
                          showDragHandle: true,
                        );
                        if (choice == -1 && context.mounted) {
                          await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                        }
                      },
                      child: const Text('Open postpone options'),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open postpone options'));
      await tester.pumpAndSettle();

      final customOption = find.text(
        '\u0648\u0642\u062a \u0645\u062e\u0635\u0635',
      );
      expect(customOption, findsOneWidget);
      await tester.ensureVisible(customOption);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(customOption).dy, lessThan(480));
      await tester.tap(customOption);
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('postpone options fit a large light-mode display', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: FilledButton(
                    onPressed: () async {
                      await showPostponeDurationSheet(
                        context: context,
                        title: 'Snooze dose reminder',
                        minuteOptions: const [10, 30, 60],
                        minuteLabelBuilder: (minutes) => 'In $minutes minutes',
                      );
                    },
                    child: const Text('Open postpone options'),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open postpone options'));
    await tester.pumpAndSettle();
    expect(find.text('In 60 minutes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
