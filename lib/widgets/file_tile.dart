import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/file_item.dart';

class FileTile extends StatelessWidget {
  final FileItem item;
  final bool grid;
  final bool selected;
  final bool selectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileTile({
    super.key,
    required this.item,
    required this.grid,
    required this.selected,
    required this.selectMode,
    required this.onTap,
    required this.onLongPress,
  });

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
        return Colors.green.shade500;
      case FileKind.video:
        return Colors.pink.shade400;
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
    final date = DateFormat('dd MMM', 'tr_TR').format(item.modified);

    if (grid) {
      return Material(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.55)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(_icon, size: 40, color: color),
                    ),
                    if (selectMode || selected)
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: selected ? cs.primary : cs.outline,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  item.isFolder ? date : item.sizeLabel,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListTile(
      selected: selected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.35),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(_icon, color: color, size: 22),
          ),
          if (selectMode || selected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: selected ? cs.primary : cs.outline,
              ),
            ),
        ],
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item.sizeLabel}  ·  $date'),
      trailing: item.isFolder
          ? Icon(Icons.chevron_right_rounded, color: cs.outline)
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
