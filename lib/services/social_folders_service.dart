import 'dart:io';

import 'package:path/path.dart' as p;

import 'storage_service.dart';

/// DosyaX/Sosyal/... auto structure + links to app media folders when present.
class SocialFoldersService {
  SocialFoldersService._();
  static final SocialFoldersService instance = SocialFoldersService._();

  static const platforms = ['Instagram', 'WhatsApp', 'Telegram', 'Threads'];
  static const subFolders = ['Fotograflar', 'Videolar', 'Belgeler', 'Hikayeler'];

  String? _sosyalRoot;

  Future<String> get sosyalRoot async {
    if (_sosyalRoot != null) return _sosyalRoot!;
    final root = await StorageService.instance.primaryRoot;
    final path = p.join(root, 'DosyaX', 'Sosyal');
    await Directory(path).create(recursive: true);
    _sosyalRoot = path;
    return path;
  }

  /// Create full tree once (idempotent).
  Future<Map<String, String>> ensureCreated() async {
    final base = await sosyalRoot;
    final paths = <String, String>{'Sosyal': base};

    for (final platform in platforms) {
      final plat = p.join(base, platform);
      await Directory(plat).create(recursive: true);
      paths[platform] = plat;
      for (final sub in subFolders) {
        // Threads/WhatsApp may not need Hikayeler equally — still create for consistency
        if (platform == 'Threads' && sub == 'Belgeler') continue;
        final dir = Directory(p.join(plat, sub));
        if (!await dir.exists()) await dir.create(recursive: true);
      }
    }

    // Discover native app folders if they exist (read-only shortcuts)
    final root = await StorageService.instance.primaryRoot;
    final native = <String, String>{
      'WA Medya': p.join(root, 'WhatsApp', 'Media'),
      'WA Resim': p.join(root, 'WhatsApp', 'Media', 'WhatsApp Images'),
      'WA Video': p.join(root, 'WhatsApp', 'Media', 'WhatsApp Video'),
      'Telegram': p.join(root, 'Telegram'),
      'IG': p.join(root, 'Android', 'media', 'com.instagram.android'),
    };
    for (final e in native.entries) {
      if (Directory(e.value).existsSync()) {
        paths['~${e.key}'] = e.value;
      }
    }

    return paths;
  }

  Future<Map<String, String>> platformShortcuts() async {
    final all = await ensureCreated();
    return {
      for (final e in all.entries)
        if (platforms.contains(e.key) || e.key == 'Sosyal') e.key: e.value,
    };
  }

  /// Guess target under Sosyal from filename / source path.
  Future<String> suggestDestFor(String sourcePath) async {
    final base = await sosyalRoot;
    final name = p.basename(sourcePath).toLowerCase();
    final full = sourcePath.toLowerCase();

    String platform = 'Instagram';
    if (full.contains('whatsapp') || name.startsWith('img-') || name.startsWith('vid-')) {
      platform = 'WhatsApp';
    } else if (full.contains('telegram') || name.startsWith('image_') && full.contains('telegram')) {
      platform = 'Telegram';
    } else if (full.contains('threads')) {
      platform = 'Threads';
    } else if (full.contains('instagram') || full.contains('ig_')) {
      platform = 'Instagram';
    }

    final ext = p.extension(name);
    String sub = 'Belgeler';
    const images = {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.gif'};
    const videos = {'.mp4', '.mkv', '.mov', '.webm', '.3gp'};
    if (images.contains(ext)) {
      sub = name.contains('story') || name.contains('hikaye') ? 'Hikayeler' : 'Fotograflar';
    } else if (videos.contains(ext)) {
      sub = 'Videolar';
    }

    final destDir = p.join(base, platform, sub);
    await Directory(destDir).create(recursive: true);
    return destDir;
  }
}
