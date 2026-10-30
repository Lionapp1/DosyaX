import 'package:flutter/material.dart';

import '../models/file_item.dart';
import '../services/app_settings.dart';
import '../services/private_vault.dart';
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

  void _open(FileItem item) {
    if (item.isFolder) return;
    if (item.kind == FileKind.image) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(path: item.path, title: item.name),
        ),
      );
      return;
    }
    if (item.kind == FileKind.video) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(path: item.path, title: item.name),
        ),
      );
    }
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
                settings.hasPrivatePin
                    ? 'PIN ile gir'
                    : 'Ilk sefer: PIN olustur',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Dosyalar yalnizca bu uygulamada saklanir.',
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
        title: const Text('Ozel alan'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Kilitle',
            onPressed: () => setState(() {
              _unlocked = false;
              _pinCtrl.clear();
              _items = [];
            }),
            icon: const Icon(Icons.lock_outline_rounded),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'Bos — dosya yoneticisinden kopyalayarak ekleyebilirsin\n(ileride tasi butonu eklenecek)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
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
                      onLongPress: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Silinsin mi?'),
                            content: Text(item.name),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Iptal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await PrivateVault.instance.deleteAt(item.path);
                          await _load();
                        }
                      },
                    );
                  },
                ),
    );
  }
}
