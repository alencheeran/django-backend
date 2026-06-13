import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'views/auth_view.dart';
import 'views/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const ApexTradeApp(),
    ),
  );
}

class ApexTradeApp extends ConsumerWidget {
  const ApexTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'ApexTrade Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Electric Indigo
          secondary: Color(0xFF10B981), // Emerald Green
          surface: Color(0xFF131B2E), // Deep slate card/surface
          error: Color(0xFFF43F5E), // Rose red
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFF8FAFC), // Off-white text
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F1E),
        dividerColor: const Color(0xFF1E293B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131B2E),
          foregroundColor: Color(0xFFF8FAFC),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF131B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFF64748B)),
          floatingLabelStyle: TextStyle(color: Color(0xFF6366F1)),
          prefixIconColor: Color(0xFF6366F1),
          suffixIconColor: Color(0xFF64748B),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: authState.status == AuthStatus.authenticated
          ? const HomeShell()
          : const AuthView(),
    );
  }
}
