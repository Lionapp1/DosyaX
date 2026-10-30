import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/file_item.dart';
import 'social_folders_service.dart';

List<FileItem> listDirSync(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];

  final items = <FileItem>[];
  try {
    final entities = dir.listSync(followLinks: false);
    for (final e in entities) {
      try {
        final item = FileItem.fromPathSync(e.path);
        if (item != null) items.add(item);
      } catch (_) {
        // skip unreadable entry, keep listing
      }
      if (items.length >= 3000) break;
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

    try {
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
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      _primaryRoot = docs.path;
      return docs.path;
    } catch (_) {
      _primaryRoot = Directory.systemTemp.path;
      return _primaryRoot!;
    }
  }

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
    try {
      final root = await primaryRoot;
      Map<String, String> social = {};
      try {
        social = await SocialFoldersService.instance.platformShortcuts();
      } catch (_) {}

      final map = <String, String>{
        'Depolama': root,
        'Indirilenler': p.join(root, 'Download'),
        ...social,
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
    } catch (_) {
      return {};
    }
  }

  /// True only with all-files access (Android 11+ MANAGE_EXTERNAL_STORAGE).
  Future<bool> hasFullAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.manageExternalStorage.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasStorageAccess() async {
    if (_accessCache == true) return true;
    if (!Platform.isAndroid) {
      _accessCache = true;
      return true;
    }
    try {
      if (await Permission.manageExternalStorage.isGranted) {
        _accessCache = true;
        return true;
      }
      if (await Permission.storage.isGranted) {
        _accessCache = true;
        return true;
      }
      // Android 13+ partial media still allows browsing some dirs
      final photos = await Permission.photos.isGranted;
      final videos = await Permission.videos.isGranted;
      final audio = await Permission.audio.isGranted;
      if (photos || videos || audio) {
        _accessCache = true;
        return true;
      }
    } catch (_) {}
    _accessCache = false;
    return false;
  }

  /// Request everything; for full access opens system "All files" page.
  Future<bool> requestStorageAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      // 1) Prefer all-files access
      var manage = await Permission.manageExternalStorage.status;
      if (!manage.isGranted) {
        manage = await Permission.manageExternalStorage.request();
      }
      if (manage.isGranted) {
        _accessCache = true;
        return true;
      }
      // Permanently denied / needs settings
      if (manage.isPermanentlyDenied || manage.isDenied) {
        // Still request media + storage for partial access
        await [
          Permission.storage,
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();
      }

      final storage = await Permission.storage.request();
      final media = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();

      final ok = storage.isGranted ||
          media.values.any((s) => s.isGranted) ||
          await Permission.manageExternalStorage.isGranted;
      _accessCache = ok;
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openFullAccessSettings() async {
    try {
      // Opens app settings; on many devices user can enable "Files and media / All files"
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  void clearAccessCache() => _accessCache = null;

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
      items = await Future<List<FileItem>>.microtask(() => listDirSync(dirPath));
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
      items =
          items.where((i) => i.kind == filterKind || i.isFolder).toList();
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
    try {
      return await OpenFilex.open(item.path);
    } catch (_) {
      return OpenResult(type: ResultType.error, message: 'open failed');
    }
  }

  Future<void> share(FileItem item) async {
    if (item.isFolder) return;
    try {
      await Share.shareXFiles([XFile(item.path)], text: item.name);
    } catch (_) {}
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
