import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/file_item.dart';
import 'storage_service.dart';

class PrivateVault {
  PrivateVault._();
  static final PrivateVault instance = PrivateVault._();

  Future<Directory> rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'dosyax_private'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> get rootPath async => (await rootDir()).path;

  Future<List<FileItem>> list() async {
    final path = await rootPath;
    return StorageService.instance.listDirectory(path, forceRefresh: true);
  }

  Future<bool> importFile(String sourcePath) async {
    try {
      final name = p.basename(sourcePath);
      final dest = p.join(await rootPath, name);
      await File(sourcePath).copy(dest);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAt(String path) async {
    try {
      final root = await rootPath;
      if (!path.startsWith(root)) return false;
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else {
        await File(path).delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
