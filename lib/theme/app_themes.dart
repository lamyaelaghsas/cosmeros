import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CosmerosTheme { nebuleuse, aurore, solaire, vide }

CosmerosTheme themeFromKey(String? key) => CosmerosTheme.values
    .firstWhere((t) => t.name == key, orElse: () => CosmerosTheme.nebuleuse);

@immutable
class CosmerosPalette extends ThemeExtension<CosmerosPalette> {
  final Color space; // fond
  final Color surface;
  final Color text;
  final Color muted;
  final Color accent; // le néon dominant
  final Color secondary; // néon secondaire, utilisé rarement
  final List<Color> planet;

  const CosmerosPalette({
    required this.space,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.secondary,
    required this.planet,
  });

  @override
  CosmerosPalette copyWith() => this;

  @override
  CosmerosPalette lerp(covariant ThemeExtension<CosmerosPalette>? other, double t) {
    if (other is! CosmerosPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension CosmerosThemeInfo on CosmerosTheme {
  String get label => switch (this) {
        CosmerosTheme.nebuleuse => 'Nébuleuse',
        CosmerosTheme.aurore => 'Aurore',
        CosmerosTheme.solaire => 'Solaire',
        CosmerosTheme.vide => 'Void',
      };

  CosmerosPalette get palette => switch (this) {
        CosmerosTheme.nebuleuse => const CosmerosPalette(
            space: Color(0xFF05060F),
            surface: Color(0xFF12152B),
            text: Color(0xFFEEF0FF),
            muted: Color(0xFF9AA0C3),
            accent: Color(0xFF4FE3FF),
            secondary: Color(0xFF8B6CFF),
            planet: [Color(0xFFC9B8FF), Color(0xFF8B6CFF), Color(0xFF1B1240)],
          ),
        CosmerosTheme.aurore => const CosmerosPalette(
            space: Color(0xFF040B09),
            surface: Color(0xFF0E1F1A),
            text: Color(0xFFE9FFF4),
            muted: Color(0xFF8FB3A4),
            accent: Color(0xFF7DFFB2),
            secondary: Color(0xFF3DD6C6),
            planet: [Color(0xFFD2FFE6), Color(0xFF3DD6A0), Color(0xFF06201A)],
          ),
        CosmerosTheme.solaire => const CosmerosPalette(
            space: Color(0xFF0C0704),
            surface: Color(0xFF22140B),
            text: Color(0xFFFFF3E6),
            muted: Color(0xFFBFA48C),
            accent: Color(0xFFFF9F43),
            secondary: Color(0xFFFF5A5F),
            planet: [Color(0xFFFFE7B8), Color(0xFFFF9F43), Color(0xFF2A1200)],
          ),
        CosmerosTheme.vide => const CosmerosPalette(
            space: Color(0xFF000000),
            surface: Color(0xFF111111),
            text: Color(0xFFFFFFFF),
            muted: Color(0xFF9A9A9A),
            accent: Color(0xFFFFFFFF),
            secondary: Color(0xFF6E6E6E),
            planet: [Color(0xFFFFFFFF), Color(0xFF8A8A8A), Color(0xFF0A0A0A)],
          ),
      };
}

ThemeData buildTheme(CosmerosTheme t) {
  final p = t.palette;
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.space,
    colorScheme: ColorScheme.dark(
      primary: p.accent,
      onPrimary: p.space,
      secondary: p.secondary,
      surface: p.surface,
      onSurface: p.text,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme)
        .apply(bodyColor: p.text, displayColor: p.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.text.withValues(alpha: 0.06),
      hintStyle: TextStyle(color: p.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface,
      contentTextStyle: TextStyle(color: p.text),
    ),
    extensions: [p],
  );
}

extension PaletteContext on BuildContext {
  CosmerosPalette get palette => Theme.of(this).extension<CosmerosPalette>()!;
}

TextStyle displayStyle(BuildContext context, double size,
        {FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.getFont('Unbounded',
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.palette.text);

class ThemeController extends ChangeNotifier {
  CosmerosTheme _theme = CosmerosTheme.nebuleuse;
  CosmerosTheme get theme => _theme;

  void set(CosmerosTheme t) {
    if (t == _theme) return;
    _theme = t;
    notifyListeners();
  }
}
