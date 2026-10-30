import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DosyaXApp());
}

class DosyaXApp extends StatelessWidget {
  const DosyaXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DosyaX',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await StorageService.instance.hasStorageAccess();
    if (mounted) setState(() => _granted = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_granted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_granted == false) {
      return PermissionScreen(
        onGranted: () => setState(() => _granted = true),
      );
    }
    return const HomeScreen();
  }
}
