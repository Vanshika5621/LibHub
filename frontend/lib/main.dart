import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'constants.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/navigation_holder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await sb.Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const LibHubApp(),
    ),
  );
}

class LibHubApp extends StatefulWidget {
  const LibHubApp({super.key});

  @override
  State<LibHubApp> createState() => _LibHubAppState();
}

class _LibHubAppState extends State<LibHubApp> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == sb.AuthChangeEvent.signedIn) {
        context.read<AppState>().loadUserData();
      } else if (event == sb.AuthChangeEvent.signedOut) {
        context.read<AppState>().signOut();
      }
    });

    // Load if already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sb.Supabase.instance.client.auth.currentUser != null) {
        context.read<AppState>().loadUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'LibHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.isLoggedIn) {
      return const NavigationHolder();
    }
    return const LoginScreen();
  }
}
