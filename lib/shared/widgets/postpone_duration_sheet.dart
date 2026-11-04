import 'package:flutter/material.dart';

/// Presents postponement options in a sheet that can scroll on short screens.
/// Returns -1 for a custom time when [customLabel] is provided.
Future<int?> showPostponeDurationSheet({
  required BuildContext context,
  required String title,
  required List<int> minuteOptions,
  required String Function(int minutes) minuteLabelBuilder,
  String? customLabel,
  bool showDragHandle = false,
}) => showModalBottomSheet<int>(
  context: context,
  useSafeArea: true,
  showDragHandle: showDragHandle,
  builder: (sheetContext) {
    final theme = Theme.of(sheetContext);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            for (final minutes in minuteOptions)
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.snooze_rounded),
                title: Text(minuteLabelBuilder(minutes)),
                onTap: () => Navigator.pop(sheetContext, minutes),
              ),
            if (customLabel != null)
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(customLabel),
                onTap: () => Navigator.pop(sheetContext, -1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  },
);
