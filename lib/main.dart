import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'core/theme/theme_provider.dart';
import 'package:e_ticketing/core/providers/shared_prefs_provider.dart';
import 'package:e_ticketing/core/services/notification_service.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';

void main() async {
  // 1. Wajib panggil ini agar SharedPreferences bisa berjalan di native
  WidgetsFlutterBinding.ensureInitialized(); 

  await NotificationService.init();

  // 2. Inisialisasi SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // 3. Masukkan instance prefs ke provider agar bisa dipakai di tempat lain
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Ticketing Helpdesk',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
