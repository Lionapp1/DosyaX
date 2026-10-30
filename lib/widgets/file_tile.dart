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
        return Icons.movie_rounded;
      case FileKind.audio:
        return Icons.audiotrack_rounded;
      case FileKind.document:
        return Icons.picture_as_pdf_rounded;
      case FileKind.archive:
        return Icons.folder_zip_rounded;
      case FileKind.code:
        return Icons.code_rounded;
      case FileKind.apk:
        return Icons.android_rounded;
      case FileKind.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = FileColors.of(item.kind);
    final date = DateFormat('dd.MM.yy').format(item.modified);

    if (grid) {
      return Material(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, size: 28, color: color),
                    ),
                    if (selectMode || selected)
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
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
      dense: true,
      selected: selected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_icon, color: color, size: 22),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${item.sizeLabel}  ·  $date'),
      trailing: item.isFolder
          ? Icon(Icons.chevron_right_rounded, color: cs.outline)
          : (selectMode || selected)
              ? Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? cs.primary : cs.outline,
                  size: 20,
                )
              : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
