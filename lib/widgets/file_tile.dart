import 'package:flutter/material.dart';
import '../models/file_item.dart';

class FileTile extends StatelessWidget {
  final FileItem item;
  final bool grid;

  const FileTile({super.key, required this.item, required this.grid});

  IconData get _icon {
    switch (item.kind) {
      case FileKind.folder:
        return Icons.folder_rounded;
      case FileKind.image:
        return Icons.image_rounded;
      case FileKind.video:
        return Icons.videocam_rounded;
      case FileKind.audio:
        return Icons.audiotrack_rounded;
      case FileKind.document:
        return Icons.description_rounded;
      case FileKind.archive:
        return Icons.folder_zip_rounded;
      case FileKind.code:
        return Icons.code_rounded;
      case FileKind.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _color(ColorScheme cs) {
    switch (item.kind) {
      case FileKind.folder:
        return Colors.amber.shade600;
      case FileKind.image:
        return Colors.emerald.shade500;
      case FileKind.video:
        return Colors.rose.shade400;
      case FileKind.audio:
        return Colors.purple.shade400;
      case FileKind.document:
        return Colors.blue.shade500;
      case FileKind.archive:
        return Colors.orange.shade600;
      case FileKind.code:
        return Colors.cyan.shade600;
      case FileKind.other:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _color(cs);

    if (grid) {
      return Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, size: 40, color: color),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sizeLabel,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(_icon, color: color, size: 22),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(item.sizeLabel),
      onTap: () {},
    );
  }
}
