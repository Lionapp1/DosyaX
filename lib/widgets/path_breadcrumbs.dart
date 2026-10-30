import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class PathBreadcrumbs extends StatelessWidget {
  final String path;
  final String rootPath;
  final ValueChanged<String> onTapSegment;

  const PathBreadcrumbs({
    super.key,
    required this.path,
    required this.rootPath,
    required this.onTapSegment,
  });

  List<({String label, String full})> _segments() {
    final out = <({String label, String full})>[];
    if (path.isEmpty) return out;

    // Normalize
    var cur = path;
    if (cur.endsWith('/') && cur.length > 1) {
      cur = cur.substring(0, cur.length - 1);
    }

    out.add((label: 'Depolama', full: rootPath.isEmpty ? cur : rootPath));

    if (rootPath.isNotEmpty && cur.startsWith(rootPath) && cur != rootPath) {
      final rel = cur.substring(rootPath.length);
      final parts = rel.split('/').where((e) => e.isNotEmpty).toList();
      var acc = rootPath;
      for (final part in parts) {
        acc = p.join(acc, part);
        out.add((label: part, full: acc));
      }
    } else if (cur != rootPath) {
      final parts = cur.split('/').where((e) => e.isNotEmpty).toList();
      var acc = '';
      for (final part in parts) {
        acc = '$acc/$part';
        out.add((label: part, full: acc));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final segs = _segments();
    if (segs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: segs.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(Icons.chevron_right_rounded, size: 16, color: cs.outline),
        ),
        itemBuilder: (_, i) {
          final s = segs[i];
          final isLast = i == segs.length - 1;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isLast ? null : () => onTapSegment(s.full),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.phone_android_rounded,
                        size: 14,
                        color: isLast ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                      color: isLast ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
