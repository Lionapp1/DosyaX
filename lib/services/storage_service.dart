import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/file_item.dart';

/// Fully synchronous listing for compute() — no microtask storms.
List<FileItem> listDirSync(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];

  final items = <FileItem>[];
  try {
    final entities = dir.listSync(followLinks: false);
    for (final e in entities) {
      final item = FileItem.fromPathSync(e.path);
      if (item != null) items.add(item);
      if (items.length >= 2500) break;
    }
  } catch (_) {
    return const [];
  }
  return items;
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  String? _primaryRoot;
  String? _startPath;
  bool? _accessCache;
  final Map<String, List<FileItem>> _listCache = {};
  static const int _cacheMax = 24;

  Future<String> get primaryRoot async {
    if (_primaryRoot != null) return _primaryRoot!;

    if (Platform.isAndroid) {
      for (final c in ['/storage/emulated/0', '/sdcard']) {
        if (Directory(c).existsSync()) {
          _primaryRoot = c;
          return c;
        }
      }
    }

    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      var path = ext.path;
      final marker = '/Android/data/';
      final idx = path.indexOf(marker);
      if (idx > 0) {
        path = path.substring(0, idx);
        if (Directory(path).existsSync()) {
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

  /// Prefer Download over huge root — faster first open.
  Future<String> get startPath async {
    if (_startPath != null) return _startPath!;
    final root = await primaryRoot;
    final download = p.join(root, 'Download');
    if (Directory(download).existsSync()) {
      _startPath = download;
      return download;
    }
    _startPath = root;
    return root;
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
    final out = <String, String>{};
    for (final e in map.entries) {
      if (Directory(e.value).existsSync()) out[e.key] = e.value;
    }
    if (!out.containsKey('Depolama')) out['Depolama'] = root;
    return out;
  }

  Future<bool> hasStorageAccess() async {
    if (_accessCache != null) return _accessCache!;
    if (!Platform.isAndroid) {
      _accessCache = true;
      return true;
    }
    // Single fast checks; avoid requesting all at once on every launch
    if (await Permission.manageExternalStorage.isGranted) {
      _accessCache = true;
      return true;
    }
    if (await Permission.storage.isGranted) {
      _accessCache = true;
      return true;
    }
    if (await Permission.photos.isGranted) {
      _accessCache = true;
      return true;
    }
    _accessCache = false;
    return false;
  }

  Future<bool> requestStorageAccess() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.request().isGranted) {
      _accessCache = true;
      return true;
    }
    final results = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    final ok = results.values.any((s) => s.isGranted);
    _accessCache = ok;
    return ok;
  }

  void invalidateCache([String? path]) {
    if (path == null) {
      _listCache.clear();
    } else {
      _listCache.remove(path);
    }
  }

  Future<List<FileItem>> listDirectory(
    String dirPath, {
    SortBy sortBy = SortBy.name,
    bool ascending = true,
    String query = '',
    FileKind? filterKind,
    bool forceRefresh = false,
  }) async {
    List<FileItem> items;
    if (!forceRefresh && _listCache.containsKey(dirPath)) {
      items = List<FileItem>.of(_listCache[dirPath]!);
    } else {
      try {
        items = await compute(listDirSync, dirPath);
      } catch (_) {
        items = listDirSync(dirPath);
      }
      _listCache[dirPath] = List<FileItem>.of(items);
      if (_listCache.length > _cacheMax) {
        _listCache.remove(_listCache.keys.first);
      }
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      items = items.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    if (filterKind != null) {
      items = items
          .where((i) => i.kind == filterKind || i.isFolder)
          .toList();
    }

    int cmp(FileItem a, FileItem b) {
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
      invalidateCache(p.dirname(item.path));
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
      invalidateCache(parent);
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
      invalidateCache(parentPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
