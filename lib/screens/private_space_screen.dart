import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../models/file_item.dart';
import '../services/app_settings.dart';
import '../services/private_vault.dart';
import '../services/storage_service.dart';
import '../widgets/file_tile.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

class PrivateSpaceScreen extends StatefulWidget {
  const PrivateSpaceScreen({super.key});

  @override
  State<PrivateSpaceScreen> createState() => _PrivateSpaceScreenState();
}

class _PrivateSpaceScreenState extends State<PrivateSpaceScreen> {
  bool _unlocked = false;
  bool _loading = false;
  bool _grid = true;
  List<FileItem> _items = [];
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await PrivateVault.instance.list();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _tryUnlock() async {
    final settings = AppSettings.instance;
    final pin = _pinCtrl.text.trim();
    if (!settings.hasPrivatePin) {
      if (pin.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az 4 haneli PIN sec')),
        );
        return;
      }
      await settings.setPrivatePin(pin);
      setState(() => _unlocked = true);
      await _load();
      return;
    }
    if (settings.checkPin(pin)) {
      setState(() => _unlocked = true);
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yanlis PIN')),
      );
    }
  }

  Future<void> _open(FileItem item) async {
    if (item.isFolder) return;
    if (item.kind == FileKind.image) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(path: item.path, title: item.name),
        ),
      );
      return;
    }
    if (item.kind == FileKind.video) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(path: item.path, title: item.name),
        ),
      );
      return;
    }
    await StorageService.instance.open(item);
  }

  Future<void> _sheet(FileItem item) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(item.name),
              subtitle: Text(item.sizeLabel),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Ac'),
              onTap: () {
                Navigator.pop(ctx);
                _open(item);
              },
            ),
            if (!item.isFolder)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Paylas'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await Share.shareXFiles([XFile(item.path)]);
                  } catch (_) {}
                },
              ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Yeniden adlandir'),
              onTap: () async {
                Navigator.pop(ctx);
                final ctrl = TextEditingController(text: item.name);
                final name = await showDialog<String>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Yeni ad'),
                    content: TextField(controller: ctrl, autofocus: true),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d),
                        child: const Text('Iptal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(d, ctrl.text),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
                if (name != null && name.trim().isNotEmpty) {
                  final dest = p.join(p.dirname(item.path), name.trim());
                  try {
                    if (item.isFolder) {
                      await Directory(item.path).rename(dest);
                    } else {
                      await File(item.path).rename(dest);
                    }
                    await _load();
                  } catch (_) {}
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all),
              title: const Text('Yolu kopyala'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.path));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: cs.error),
              title: Text('Sil', style: TextStyle(color: cs.error)),
              onTap: () async {
                Navigator.pop(ctx);
                await PrivateVault.instance.deleteAt(item.path);
                await _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = AppSettings.instance;

    if (!_unlocked) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Ozel alan'),
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                settings.hasPrivatePin ? 'PIN ile gir' : 'Ilk sefer: PIN olustur',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Dosyalar yalnizca bu uygulamada saklanir. Uzun bas ile yonet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _tryUnlock(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _tryUnlock,
                child: Text(settings.hasPrivatePin ? 'Ac' : 'PIN kaydet ve ac'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Ozel alan (${_items.length})'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
          ),
          IconButton(
            tooltip: 'Kilitle',
            onPressed: () => setState(() {
              _unlocked = false;
              _pinCtrl.clear();
              _items = [];
            }),
            icon: const Icon(Icons.lock_outline_rounded),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Bos.\nDosyalar sekmesinde uzun bas → "Ozel alana kopyala"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              : _grid
                  ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return FileTile(
                          item: item,
                          grid: true,
                          selected: false,
                          selectMode: false,
                          onTap: () => _open(item),
                          onLongPress: () => _sheet(item),
                        );
                      },
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return FileTile(
                          item: item,
                          grid: false,
                          selected: false,
                          selectMode: false,
                          onTap: () => _open(item),
                          onLongPress: () => _sheet(item),
                        );
                      },
                    ),
    );
  }
}
