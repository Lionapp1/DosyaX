import 'package:flutter/material.dart';

IconData iconForQuickLabel(String label) {
  final l = label.toLowerCase();
  if (l.contains('depolama')) return Icons.storage_rounded;
  if (l.contains('indir')) return Icons.download_rounded;
  if (l.contains('sosyal')) return Icons.hub_rounded;
  if (l.contains('instagram') || l == '~instagram' || l == 'ig') {
    return Icons.camera_alt_rounded;
  }
  if (l.contains('whatsapp') || l.startsWith('~wa')) return Icons.chat_rounded;
  if (l.contains('telegram') || l.startsWith('~telegram')) {
    return Icons.send_rounded;
  }
  if (l.contains('threads')) return Icons.alternate_email_rounded;
  if (l.contains('fotograf') || l.contains('resim') || l.contains('dcim')) {
    return Icons.photo_library_rounded;
  }
  if (l.contains('video') || l.contains('movie')) return Icons.movie_rounded;
  if (l.contains('muzik') || l.contains('music')) return Icons.library_music_rounded;
  if (l.contains('belge') || l.contains('document')) {
    return Icons.description_rounded;
  }
  return Icons.folder_rounded;
}

class QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const QuickChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = iconForQuickLabel(label);
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: selected ? cs.onSecondaryContainer : cs.primary),
      label: Text(label),
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      selectedColor: cs.secondaryContainer,
    );
  }
}
