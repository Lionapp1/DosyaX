import 'dart:io';

import 'package:path/path.dart' as p;

enum FileKind { folder, image, video, audio, document, archive, code, other }

enum SortBy { name, size, modified }

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

  String get ext => isFolder ? '' : p.extension(name).toLowerCase();

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
    const images = {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.svg',
    };
    const videos = {
      '.mp4',
      '.mkv',
      '.avi',
      '.mov',
      '.wmv',
      '.webm',
      '.3gp',
    };
    const audio = {
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.m4a',
      '.wma',
    };
    const docs = {
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.rtf',
      '.odt',
      '.csv',
    };
    const archives = {'.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'};
    const code = {
      '.dart',
      '.js',
      '.ts',
      '.json',
      '.xml',
      '.html',
      '.css',
      '.py',
      '.java',
      '.kt',
      '.c',
      '.cpp',
      '.h',
      '.md',
      '.yml',
      '.yaml',
      '.sh',
    };
    if (images.contains(e)) return FileKind.image;
    if (videos.contains(e)) return FileKind.video;
    if (audio.contains(e)) return FileKind.audio;
    if (docs.contains(e)) return FileKind.document;
    if (archives.contains(e)) return FileKind.archive;
    if (code.contains(e)) return FileKind.code;
    return FileKind.other;
  }

  static Future<FileItem?> fromEntity(FileSystemEntity entity) async {
    try {
      final stat = await entity.stat();
      final isDir = stat.type == FileSystemEntityType.directory;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) return null;
      return FileItem(
        path: entity.path,
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
