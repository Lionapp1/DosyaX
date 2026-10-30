import 'package:flutter/material.dart';

import '../services/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                      subtitle: const Text('Dosya listesinde grid acik gelsin'),
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
                    settings.hasPrivatePin
                        ? 'PIN ayarli'
                        : 'PIN henuz yok',
                  ),
                  subtitle: const Text('Ozel sekmesinden PIN belirleyebilirsin'),
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
                  subtitle: Text('v0.4.0 — hizli dosya yoneticisi'),
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
