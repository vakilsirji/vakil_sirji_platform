import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';

import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(const VakilSirjiApp());
}

class VakilSirjiApp extends StatelessWidget {
  const VakilSirjiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp.router(
        title: 'GharBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F172A),
            primary: const Color(0xFF0F172A),
            secondary: const Color(0xFFD97706),
            background: const Color(0xFFF8FAFC),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 1,
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
