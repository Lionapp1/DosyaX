import 'dart:io';

import 'package:path/path.dart' as p;

import 'storage_service.dart';
import 'transfer_service.dart';

class SocialFoldersService {
  SocialFoldersService._();
  static final SocialFoldersService instance = SocialFoldersService._();

  static const platforms = [
    'Instagram',
    'WhatsApp',
    'Telegram',
    'Threads',
    'X',
  ];
  static const subFolders = ['Fotograflar', 'Videolar', 'Belgeler', 'Hikayeler'];

  static const _imageExt = {
    '.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif', '.bmp',
  };
  static const _videoExt = {
    '.mp4', '.mkv', '.mov', '.webm', '.3gp', '.avi',
  };

  String? _sosyalRoot;

  Future<String> get sosyalRoot async {
    if (_sosyalRoot != null) return _sosyalRoot!;
    final root = await StorageService.instance.primaryRoot;
    final path = p.join(root, 'DosyaX', 'Sosyal');
    await Directory(path).create(recursive: true);
    _sosyalRoot = path;
    return path;
  }

  Future<Map<String, String>> ensureCreated() async {
    final base = await sosyalRoot;
    final paths = <String, String>{'Sosyal': base};

    for (final platform in platforms) {
      final plat = p.join(base, platform);
      await Directory(plat).create(recursive: true);
      paths[platform] = plat;
      for (final sub in subFolders) {
        if ((platform == 'Threads' || platform == 'X') && sub == 'Belgeler') {
          continue;
        }
        final dir = Directory(p.join(plat, sub));
        if (!await dir.exists()) await dir.create(recursive: true);
      }
    }

    final native = await nativeSources();
    for (final e in native.entries) {
      for (final path in e.value) {
        if (Directory(path).existsSync()) {
          paths['~${e.key}'] = path;
          break;
        }
      }
    }

    return paths;
  }

  Future<Map<String, List<String>>> nativeSources() async {
    final root = await StorageService.instance.primaryRoot;
    return {
      'WhatsApp': [
        p.join(root, 'WhatsApp', 'Media', 'WhatsApp Images'),
        p.join(root, 'WhatsApp', 'Media', 'WhatsApp Video'),
        p.join(root, 'WhatsApp', 'Media', 'WhatsApp Documents'),
        p.join(root, 'WhatsApp', 'Media', 'WhatsApp Animated Gifs'),
        p.join(root, 'Android', 'media', 'com.whatsapp', 'WhatsApp', 'Media',
            'WhatsApp Images'),
        p.join(root, 'Android', 'media', 'com.whatsapp', 'WhatsApp', 'Media',
            'WhatsApp Video'),
        p.join(root, 'Android', 'media', 'com.whatsapp.w4b', 'WhatsApp Business',
            'Media', 'WhatsApp Images'),
      ],
      'Telegram': [
        p.join(root, 'Telegram', 'Telegram Images'),
        p.join(root, 'Telegram', 'Telegram Video'),
        p.join(root, 'Telegram', 'Telegram Documents'),
        p.join(root, 'Telegram', 'Telegram Files'),
        p.join(root, 'Android', 'media', 'org.telegram.messenger'),
      ],
      'Instagram': [
        p.join(root, 'Pictures', 'Instagram'),
        p.join(root, 'DCIM', 'Instagram'),
        p.join(root, 'Android', 'media', 'com.instagram.android'),
      ],
      'Threads': [
        p.join(root, 'Pictures', 'Threads'),
        p.join(root, 'DCIM', 'Threads'),
        p.join(root, 'Android', 'media', 'com.instagram.barcelona'),
      ],
      'X': [
        p.join(root, 'Pictures', 'Twitter'),
        p.join(root, 'Pictures', 'X'),
        p.join(root, 'DCIM', 'Twitter'),
        p.join(root, 'Android', 'media', 'com.twitter.android'),
        p.join(root, 'Android', 'data', 'com.twitter.android', 'files'),
      ],
    };
  }

  Future<Map<String, String>> platformShortcuts() async {
    final all = await ensureCreated();
    return {
      for (final e in all.entries)
        if (platforms.contains(e.key) ||
            e.key == 'Sosyal' ||
            e.key.startsWith('~'))
          e.key: e.value,
    };
  }

  Future<String> suggestDestFor(String sourcePath) async {
    final base = await sosyalRoot;
    final name = p.basename(sourcePath).toLowerCase();
    final full = sourcePath.toLowerCase();

    String platform = 'Instagram';
    if (full.contains('whatsapp') ||
        name.startsWith('img-') ||
        name.startsWith('vid-') ||
        name.startsWith('aud-')) {
      platform = 'WhatsApp';
    } else if (full.contains('telegram') || full.contains('org.telegram')) {
      platform = 'Telegram';
    } else if (full.contains('threads') || full.contains('barcelona')) {
      platform = 'Threads';
    } else if (full.contains('twitter') ||
        full.contains('com.twitter') ||
        full.contains('/x/') ||
        name.startsWith('tw_')) {
      platform = 'X';
    } else if (full.contains('instagram') || full.contains('ig_')) {
      platform = 'Instagram';
    }

    final ext = p.extension(name);
    String sub = 'Belgeler';
    if (_imageExt.contains(ext)) {
      sub = (name.contains('story') || name.contains('hikaye'))
          ? 'Hikayeler'
          : 'Fotograflar';
    } else if (_videoExt.contains(ext)) {
      sub = 'Videolar';
    }

    final destDir = p.join(base, platform, sub);
    await Directory(destDir).create(recursive: true);
    return destDir;
  }

  Future<int> scanAndImport({int maxFiles = 120}) async {
    await ensureCreated();
    final sources = await nativeSources();
    var enqueued = 0;

    for (final entry in sources.entries) {
      final platform = entry.key;
      for (final dirPath in entry.value) {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) continue;

        List<FileSystemEntity> entities;
        try {
          entities = dir.listSync(followLinks: false);
        } catch (_) {
          continue;
        }

        entities.sort((a, b) {
          try {
            return b.statSync().modified.compareTo(a.statSync().modified);
          } catch (_) {
            return 0;
          }
        });

        for (final e in entities) {
          if (enqueued >= maxFiles) return enqueued;
          if (e is! File) continue;
          final name = p.basename(e.path);
          if (name.startsWith('.')) continue;
          final ext = p.extension(name).toLowerCase();
          if (!_imageExt.contains(ext) &&
              !_videoExt.contains(ext) &&
              ext != '.pdf' &&
              ext != '.doc' &&
              ext != '.docx' &&
              ext != '.opus' &&
              ext != '.ogg' &&
              ext != '.mp3') {
            continue;
          }

          final destDir = await suggestDestFor(e.path);
          final forced = p.join(await sosyalRoot, platform, p.basename(destDir));
          await Directory(forced).create(recursive: true);
          final destFile = p.join(forced, name);
          if (File(destFile).existsSync()) continue;

          TransferService.instance.enqueue(
            sourcePath: e.path,
            destDir: forced,
            op: TransferOp.copy,
          );
          enqueued++;
        }
      }
    }
    return enqueued;
  }
}
