import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../widgets/file_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _grid = true;
  String _query = '';

  // Demo data — storage API bağlanınca değişecek
  final List<FileItem> _files = [
    FileItem(
      id: '1',
      name: 'İndirilenler',
      kind: FileKind.folder,
      size: 0,
      path: '/Download',
      isFolder: true,
      modified: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FileItem(
      id: '2',
      name: 'foto.jpg',
      kind: FileKind.image,
      size: 2450000,
      path: '/foto.jpg',
      isFolder: false,
      modified: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    FileItem(
      id: '3',
      name: 'rapor.pdf',
      kind: FileKind.document,
      size: 5120000,
      path: '/rapor.pdf',
      isFolder: false,
      modified: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FileItem(
      id: '4',
      name: 'video.mp4',
      kind: FileKind.video,
      size: 48200000,
      path: '/video.mp4',
      isFolder: false,
      modified: DateTime.now().subtract(const Duration(days: 5)),
    ),
    FileItem(
      id: '5',
      name: 'yedek.zip',
      kind: FileKind.archive,
      size: 120000000,
      path: '/yedek.zip',
      isFolder: false,
      modified: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    FileItem(
      id: '6',
      name: 'main.dart',
      kind: FileKind.code,
      size: 12400,
      path: '/main.dart',
      isFolder: false,
      modified: DateTime.now(),
    ),
  ];

  List<FileItem> get _filtered {
    if (_query.isEmpty) return _files;
    final q = _query.toLowerCase();
    return _files.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DosyaX'),
        actions: [
          IconButton(
            tooltip: _grid ? 'Liste' : 'Izgara',
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: 'Ara',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Dosya veya klasör ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Sonuç yok',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : _grid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => FileTile(item: _filtered[i], grid: true),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => FileTile(item: _filtered[i], grid: false),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yükleme yakında')),
          );
        },
        icon: const Icon(Icons.upload_rounded),
        label: const Text('Yükle'),
      ),
    );
  }
}
