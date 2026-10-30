import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionScreen({super.key, required this.onGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _busy = false;

  Future<void> _request() async {
    setState(() => _busy = true);
    final ok = await StorageService.instance.requestStorageAccess();
    setState(() => _busy = false);
    if (ok) {
      widget.onGranted();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tam erisim icin Ayarlar > DosyaX > Dosyalari yonet iznini ac',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.folder_special_rounded, size: 88, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'DosyaX',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Telefonundaki gercek dosyalari hizli ve guvenli yonetmek icin depolama izni gerekli.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _request,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: Text(_busy ? 'Isteniyor...' : 'Izin ver'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onGranted,
                child: const Text('Simdilik atla (sinirli)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
