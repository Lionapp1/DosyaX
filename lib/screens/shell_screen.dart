import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/transfer_banner.dart';
import 'home_screen.dart';
import 'private_space_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  // Keep Home alive so back/path state persist
  final _homeKey = GlobalKey<HomeScreenState>();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // Image/video routes handled by Navigator above shell
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
          return;
        }

        // Other tabs → go to Dosyalar
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }

        // Dosyalar: folder up / exit select
        final handled = await _homeKey.currentState?.handleSystemBack() ?? false;
        if (handled) return;

        // At root → leave app
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        resizeToAvoidBottomInset: true,
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(key: _homeKey),
            const PrivateSpaceScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TransferBanner(),
            NavigationBar(
              selectedIndex: _index,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              indicatorColor: cs.primaryContainer,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder_rounded),
                  label: 'Dosyalar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.lock_outline_rounded),
                  selectedIcon: Icon(Icons.lock_rounded),
                  label: 'Ozel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Ayarlar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
