import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/file_item.dart';

/// Heavy listing off the UI isolate for large folders.
Future<List<FileItem>> _listDirIsolate(String dirPath) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) return [];

  final entities = <FileSystemEntity>[];
  try {
    await for (final e in dir.list(followLinks: false)) {
      entities.add(e);
      if (entities.length > 5000) break; // safety cap
    }
  } catch (_) {
    return [];
  }

  final items = <FileItem>[];
  for (final e in entities) {
    final item = await FileItem.fromEntity(e);
    if (item != null) items.add(item);
  }
  return items;
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  String? _primaryRoot;

  Future<String> get primaryRoot async {
    if (_primaryRoot != null) return _primaryRoot!;

    // Prefer shared external storage on Android.
    if (Platform.isAndroid) {
      final candidates = [
        '/storage/emulated/0',
        '/sdcard',
      ];
      for (final c in candidates) {
        if (await Directory(c).exists()) {
          _primaryRoot = c;
          return c;
        }
      }
    }

    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      // Often .../Android/data/... — climb to emulated root if possible
      var path = ext.path;
      final marker = '/Android/data/';
      final idx = path.indexOf(marker);
      if (idx > 0) {
        path = path.substring(0, idx);
        if (await Directory(path).exists()) {
          _primaryRoot = path;
          return path;
        }
      }
      _primaryRoot = ext.path;
      return ext.path;
    }

    final docs = await getApplicationDocumentsDirectory();
    _primaryRoot = docs.path;
    return docs.path;
  }

  Future<Map<String, String>> quickPaths() async {
    final root = await primaryRoot;
    final map = <String, String>{
      'Depolama': root,
      'Indirilenler': p.join(root, 'Download'),
      'Fotograf': p.join(root, 'DCIM'),
      'Resimler': p.join(root, 'Pictures'),
      'Videolar': p.join(root, 'Movies'),
      'Muzik': p.join(root, 'Music'),
      'Belgeler': p.join(root, 'Documents'),
    };
    // Keep only existing dirs
    final out = <String, String>{};
    for (final e in map.entries) {
      if (await Directory(e.value).exists()) {
        out[e.key] = e.value;
      }
    }
    if (!out.containsKey('Depolama')) out['Depolama'] = root;
    return out;
  }

  Future<bool> hasStorageAccess() async {
    if (!Platform.isAndroid) return true;

    final manage = await Permission.manageExternalStorage.status;
    if (manage.isGranted) return true;

    final storage = await Permission.storage.status;
    if (storage.isGranted) return true;

    // Android 13+ media
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    final audio = await Permission.audio.status;
    if (photos.isGranted || videos.isGranted || audio.isGranted) return true;

    return false;
  }

  Future<bool> requestStorageAccess() async {
    if (!Platform.isAndroid) return true;

    // Full access preferred for a real file manager
    var manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return true;

    // Fallback scoped / legacy
    final results = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    return results.values.any((s) => s.isGranted);
  }

  Future<List<FileItem>> listDirectory(
    String dirPath, {
    SortBy sortBy = SortBy.name,
    bool ascending = true,
    String query = '',
    FileKind? filterKind,
  }) async {
    List<FileItem> items;
    try {
      // compute needs top-level or static — use isolate entry
      items = await compute(_listDirIsolate, dirPath);
    } catch (_) {
      items = await _listDirIsolate(dirPath);
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      items = items.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    if (filterKind != null) {
      items = items.where((i) => i.kind == filterKind || i.isFolder).toList();
    }

    int cmp(FileItem a, FileItem b) {
      // Folders first
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      int r;
      switch (sortBy) {
        case SortBy.name:
          r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortBy.size:
          r = a.size.compareTo(b.size);
          break;
        case SortBy.modified:
          r = a.modified.compareTo(b.modified);
          break;
      }
      return ascending ? r : -r;
    }

    items.sort(cmp);
    return items;
  }

  Future<OpenResult> open(FileItem item) async {
    if (item.isFolder) {
      return OpenResult(type: ResultType.done, message: 'folder');
    }
    return OpenFilex.open(item.path);
  }

  Future<void> share(FileItem item) async {
    if (item.isFolder) return;
    await Share.shareXFiles([XFile(item.path)], text: item.name);
  }

  Future<bool> delete(FileItem item) async {
    try {
      if (item.isFolder) {
        await Directory(item.path).delete(recursive: true);
      } else {
        await File(item.path).delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rename(FileItem item, String newName) async {
    try {
      final parent = p.dirname(item.path);
      final dest = p.join(parent, newName);
      if (item.isFolder) {
        await Directory(item.path).rename(dest);
      } else {
        await File(item.path).rename(dest);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createFolder(String parentPath, String name) async {
    try {
      final dir = Directory(p.join(parentPath, name));
      if (await dir.exists()) return false;
      await dir.create();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, int>> folderStats(String dirPath) async {
    final items = await listDirectory(dirPath);
    var files = 0;
    var folders = 0;
    var bytes = 0;
    for (final i in items) {
      if (i.isFolder) {
        folders++;
      } else {
        files++;
        bytes += i.size;
      }
    }
    return {'files': files, 'folders': folders, 'bytes': bytes};
  }
}
