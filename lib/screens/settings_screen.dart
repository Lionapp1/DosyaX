import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/social_folders_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _fullAccess;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final full = await StorageService.instance.hasFullAccess();
    if (mounted) setState(() => _fullAccess = full);
  }

  Future<void> _scanSocial() async {
    setState(() => _scanning = true);
    final n = await SocialFoldersService.instance.scanAndImport(maxFiles: 120);
    setState(() => _scanning = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n == 0
              ? 'Yeni dosya bulunamadi (izin veya bos klasor)'
              : '$n dosya kuyruga alindi — Sosyal klasorlere kopyalaniyor',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const Text('Ayarlar'),
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _sectionTitle(context, 'Erisim'),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _fullAccess == true
                            ? Icons.verified_user_rounded
                            : Icons.warning_amber_rounded,
                        color: _fullAccess == true ? Colors.green : cs.error,
                      ),
                      title: Text(
                        _fullAccess == true
                            ? 'Tum dosyalara erisim acik'
                            : 'Tam erisim yok',
                      ),
                      subtitle: const Text(
                        'Android/data, OBB, WA, TG icin "Tum dosyalar" gerekli',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await StorageService.instance
                                    .requestStorageAccess();
                                await _loadAccess();
                              },
                              icon: const Icon(Icons.lock_open, size: 18),
                              label: const Text('Izin iste'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                await StorageService.instance
                                    .openFullAccessSettings();
                              },
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text('Ayarlar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Sosyal medya'),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.travel_explore_rounded, color: cs.primary),
                      title: const Text('Medya dosyalarini tara ve getir'),
                      subtitle: const Text(
                        'WA / TG / IG / Threads / X → DosyaX/Sosyal',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _scanning ? null : _scanSocial,
                          icon: _scanning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            _scanning ? 'Taraniyor...' : 'Tara ve getir',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Gorunum'),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.brightness_6_rounded),
                      title: const Text('Tema'),
                      subtitle: Text(_themeLabel(settings.themeMode)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Sistem'),
                            icon: Icon(Icons.phone_android, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Acik'),
                            icon: Icon(Icons.light_mode, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Koyu'),
                            icon: Icon(Icons.dark_mode, size: 16),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) {
                          settings.setThemeMode(s.first);
                        },
                      ),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.grid_view_rounded),
                      title: const Text('Varsayilan izgara'),
                      value: settings.preferGrid,
                      onChanged: settings.setPreferGrid,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Ozel alan'),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(Icons.lock_rounded, color: cs.primary),
                  title: Text(
                    settings.hasPrivatePin ? 'PIN ayarli' : 'PIN henuz yok',
                  ),
                  subtitle: const Text('Ozel sekmesinden yonetilir'),
                  trailing: settings.hasPrivatePin
                      ? TextButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('PIN silinsin mi?'),
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
                            if (ok == true) await settings.clearPrivatePin();
                          },
                          child: const Text('Sifirla'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Hakkinda'),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('DosyaX'),
                  subtitle: Text(
                    'v0.6.0 (60)\n'
                    'Paket: com.dosyax.app\n'
                    'Onceki paketle cakisma olmaz — yeni kurulum',
                  ),
                  isThreeLine: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Acik',
        ThemeMode.dark => 'Koyu',
        ThemeMode.system => 'Sistem',
      };

  Widget _sectionTitle(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
