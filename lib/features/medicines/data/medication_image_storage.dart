import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';

class MedicationImageStorage {
  MedicationImageStorage(this._database);

  static const folderName = 'medication_images';
  final AppDatabase _database;
  static final _random = Random.secure();

  Future<String> savePickedImage(XFile picked) async {
    final source = File(picked.path);
    if (!await source.exists()) {
      throw const FileSystemException('Selected image is missing.');
    }
    final length = await source.length();
    if (length == 0 || length > 20 * 1024 * 1024) {
      throw const FileSystemException('Selected image is empty or too large.');
    }
    final directory = await _imageDirectory();
    await directory.create(recursive: true);
    final extension = _safeExtension(picked.path);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${_random.nextInt(1 << 32).toRadixString(16)}$extension';
    final target = File(p.join(directory.path, name));
    await source.copy(target.path);
    return p.join(folderName, name);
  }

  static Future<File?> resolveFile(String? relativePath) async {
    if (relativePath == null || relativePath.trim().isEmpty) return null;
    final normalized = p.normalize(relativePath);
    final parts = p.split(normalized);
    if (p.isAbsolute(normalized) ||
        parts.contains('..') ||
        parts.first != folderName ||
        parts.length != 2) {
      return null;
    }
    final root = await getApplicationSupportDirectory();
    final file = File(p.join(root.path, normalized));
    if (!await file.exists() || await file.length() == 0) return null;
    return file;
  }

  Future<void> deleteIfUnreferenced(String? relativePath) async {
    if (relativePath == null || relativePath.trim().isEmpty) return;
    final db = await _database.database;
    final references = await db.query(
      'medications',
      columns: ['id'],
      where: 'image_path = ?',
      whereArgs: [relativePath],
      limit: 1,
    );
    if (references.isNotEmpty) return;
    final file = await resolveFile(relativePath);
    if (file != null && await file.exists()) await file.delete();
  }

  Future<Directory> _imageDirectory() async {
    final root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, folderName));
  }

  static String _safeExtension(String sourcePath) {
    final extension = p.extension(sourcePath).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)
        ? extension
        : '.jpg';
  }
}
