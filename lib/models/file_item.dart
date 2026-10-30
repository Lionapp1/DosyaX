import 'dart:io';
import 'dart:ui' show Color;

import 'package:path/path.dart' as p;

enum FileKind { folder, image, video, audio, document, archive, code, apk, other }

enum SortBy { name, size, modified }

/// Distinctive brand colors per file kind (DosyaX identity).
class FileColors {
  static const folder = Color(0xFFF59E0B); // amber
  static const image = Color(0xFF10B981); // emerald
  static const video = Color(0xFFEC4899); // pink
  static const audio = Color(0xFF8B5CF6); // violet
  static const document = Color(0xFF3B82F6); // blue
  static const archive = Color(0xFFF97316); // orange
  static const code = Color(0xFF06B6D4); // cyan
  static const apk = Color(0xFF22C55E); // green
  static const other = Color(0xFF94A3B8); // slate

  static Color of(FileKind kind) {
    switch (kind) {
      case FileKind.folder:
        return folder;
      case FileKind.image:
        return image;
      case FileKind.video:
        return video;
      case FileKind.audio:
        return audio;
      case FileKind.document:
        return document;
      case FileKind.archive:
        return archive;
      case FileKind.code:
        return code;
      case FileKind.apk:
        return apk;
      case FileKind.other:
        return other;
    }
  }
}

class FileItem {
  final String path;
  final String name;
  final FileKind kind;
  final int size;
  final bool isFolder;
  final DateTime modified;

  const FileItem({
    required this.path,
    required this.name,
    required this.kind,
    required this.size,
    required this.isFolder,
    required this.modified,
  });

  String get id => path;

  String get sizeLabel {
    if (isFolder) return 'Klasor';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static FileKind kindFromName(String name, {required bool isDir}) {
    if (isDir) return FileKind.folder;
    final e = p.extension(name).toLowerCase();
    if (e == '.apk') return FileKind.apk;
    const images = {
      '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.svg',
    };
    const videos = {
      '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.3gp',
    };
    const audio = {
      '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma',
    };
    const docs = {
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.txt', '.rtf', '.odt', '.csv',
    };
    const archives = {'.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'};
    const code = {
      '.dart', '.js', '.ts', '.json', '.xml', '.html', '.css', '.py',
      '.java', '.kt', '.c', '.cpp', '.h', '.md', '.yml', '.yaml', '.sh',
    };
    if (images.contains(e)) return FileKind.image;
    if (videos.contains(e)) return FileKind.video;
    if (audio.contains(e)) return FileKind.audio;
    if (docs.contains(e)) return FileKind.document;
    if (archives.contains(e)) return FileKind.archive;
    if (code.contains(e)) return FileKind.code;
    return FileKind.other;
  }

  /// Fast path: sync stat, used inside isolate.
  static FileItem? fromPathSync(String path) {
    try {
      final name = p.basename(path);
      if (name.startsWith('.')) return null;
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type == FileSystemEntityType.notFound) return null;
      final isDir = type == FileSystemEntityType.directory;
      final stat = FileStat.statSync(path);
      return FileItem(
        path: path,
        name: name,
        kind: kindFromName(name, isDir: isDir),
        size: isDir ? 0 : stat.size,
        isFolder: isDir,
        modified: stat.modified,
      );
    } catch (_) {
      return null;
    }
  }
}
