import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionScreen({super.key, required this.onGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheck();
    }
  }

  Future<void> _recheck() async {
    StorageService.instance.clearAccessCache();
    final ok = await StorageService.instance.hasStorageAccess();
    if (ok && mounted) widget.onGranted();
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    final ok = await StorageService.instance.requestStorageAccess();
    final full = await StorageService.instance.hasFullAccess();
    setState(() => _busy = false);
    if (ok && mounted) {
      if (!full) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kismi izin verildi. Tum dosyalar icin "Tum dosyalara erisim" ac.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      widget.onGranted();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin verilmedi. Ayarlardan Tum dosyalara erisimi ac.'),
        ),
      );
    }
  }

  Future<void> _openSettings() async {
    await StorageService.instance.openFullAccessSettings();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
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
                'WhatsApp, Telegram, Instagram ve tum klasorleri okumak icin '
                '"Tum dosyalara erisim" izni gerekir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                '1) Izin ver\n'
                '2) Acilan ayarda "Dosyalari yonet / Tum dosyalar" secenegini ac\n'
                '3) Uygulamaya geri don',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                  fontSize: 13,
                ),
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
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Ayarlarda tam erisim ac'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onGranted,
                child: const Text('Simdilik atla (sinirli erisim)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
