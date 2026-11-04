import 'dart:io';

import 'package:flutter/material.dart';

import '../data/medication_image_storage.dart';

class MedicationImagePreview extends StatefulWidget {
  const MedicationImagePreview({
    required this.path,
    required this.temporary,
    required this.placeholder,
    this.height = 150,
    super.key,
  });

  final String? path;
  final bool temporary;
  final Widget placeholder;
  final double height;

  @override
  State<MedicationImagePreview> createState() => _MedicationImagePreviewState();
}

class _MedicationImagePreviewState extends State<MedicationImagePreview> {
  late Future<File?> _file;

  @override
  void initState() {
    super.initState();
    _file = _resolve();
  }

  @override
  void didUpdateWidget(covariant MedicationImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.temporary != widget.temporary) {
      _file = _resolve();
    }
  }

  Future<File?> _resolve() {
    if (widget.path == null) return Future.value(null);
    if (widget.temporary) return Future.value(File(widget.path!));
    return MedicationImageStorage.resolveFile(widget.path);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: FutureBuilder<File?>(
          future: _file,
          builder: (context, snapshot) {
            final file = snapshot.data;
            if (file == null) return widget.placeholder;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => widget.placeholder,
              ),
            );
          },
        ),
      ),
    ),
  );
}
