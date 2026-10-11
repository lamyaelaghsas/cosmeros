import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/shell.dart';
import 'theme/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);
  runApp(ChangeNotifierProvider(create: (_) => ThemeController(), child: const CosmerosApp()));
}

class CosmerosApp extends StatelessWidget {
  const CosmerosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().theme;
    return MaterialApp(
      title: 'Cosmeros',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(theme),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final session = auth.currentSession;
        // La clé force un nouvel écran propre à chaque changement de compte.
        return session == null
            ? const AuthScreen()
            : Shell(key: ValueKey(session.user.id));
      },
    );
  }
}
