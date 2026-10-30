enum FileKind { folder, image, video, audio, document, archive, code, other }

class FileItem {
  final String id;
  final String name;
  final FileKind kind;
  final int size;
  final String path;
  final bool isFolder;
  final DateTime modified;

  const FileItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.size,
    required this.path,
    required this.isFolder,
    required this.modified,
  });

  String get sizeLabel {
    if (isFolder) return 'Klasör';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
