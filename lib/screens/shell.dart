import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../theme/app_themes.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _db = DbService();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Applique le thème enregistré sur le compte.
    _db.profile(_db.uid).then((p) {
      if (!mounted || p == null) return;
      context.read<ThemeController>().set(themeFromKey(p['theme'] as String?));
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pages = [
      HomeScreen(onExplore: () => setState(() => _index = 1)),
      const SearchScreen(),
      ProfileScreen(userId: _db.uid, isTab: true),
    ];

    Widget navItem(int i, IconData icon, String label) {
      final selected = _index == i;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: IconButton(
            tooltip: label,
            onPressed: () => setState(() => _index = i),
            icon: Icon(icon, color: selected ? p.accent : p.muted, size: 26),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: p.text.withValues(alpha: 0.12)),
          ),
          child: Row(children: [
            navItem(0, Icons.blur_circular_rounded, 'Accueil'),
            Expanded(
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Explorer',
                  child: GestureDetector(
                    onTap: () => setState(() => _index = 1),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.secondary,
                        boxShadow: [BoxShadow(color: p.secondary.withValues(alpha: 0.75), blurRadius: 22)],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
            navItem(2, Icons.person_outline_rounded, 'Profil'),
          ]),
        ),
      ),
    );
  }
}
