import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 theme derived from the supplied My Khata screen specifications.
class AppTheme {
  static const primary = Color(0xFF13434B);
  static const primaryDark = Color(0xFFA1CED7);
  static const got = Color(0xFF2E7D32);
  static const gotDark = Color(0xFF81C784);
  static const gave = Color(0xFFC62828);
  static const gaveDark = Color(0xFFEF9A9A);

  static ThemeData get lightTheme => _theme(Brightness.light);
  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: primaryDark,
            onPrimary: Color(0xFF00363D),
            primaryContainer: Color(0xFF1E4D55),
            onPrimaryContainer: Color(0xFFBCEAF4),
            secondary: Color(0xFFBFC5E5),
            onSecondary: Color(0xFF293047),
            error: gaveDark,
            surface: Color(0xFF121414),
            onSurface: Color(0xFFE3E2E2),
            onSurfaceVariant: Color(0xFFC0C8CA),
            outline: Color(0xFF8A9294),
            outlineVariant: Color(0xFF40484A),
          )
        : const ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            primaryContainer: Color(0xFF2E5B63),
            onPrimaryContainer: Color(0xFFA3D1DA),
            secondary: Color(0xFF575D79),
            onSecondary: Colors.white,
            error: Color(0xFFBA1A1A),
            surface: Color(0xFFFAF9F9),
            onSurface: Color(0xFF1B1C1C),
            onSurfaceVariant: Color(0xFF40484A),
            outline: Color(0xFF71787A),
            outlineVariant: Color(0xFFC0C8CA),
          );

    final background = dark ? const Color(0xFF101212) : const Color(0xFFFAF9F9);
    final field = dark ? const Color(0xFF1B1D1D) : const Color(0xFFF4F3F3);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Noto Sans',
      scaffoldBackgroundColor: background,
      dividerColor: scheme.outlineVariant.withValues(alpha: .45),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontFamily: 'Noto Sans',
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1B1D1D) : const Color(0xFFF4F3F3),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
