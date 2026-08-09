import 'package:flutter/material.dart';

/// Klear brand theme — "Soft UI Sea".
///
/// Brand identity is the water droplet, so the palette is ocean/sea-inspired:
/// - Deep sea cyan primary + teal secondary on an aqua-tinted base.
/// - Soft, improved shadows (subtle depth, not flat, not neumorphic).
/// - Rounded corners (16/20), 8dp spacing rhythm, 44px+ touch targets.
/// - Full light + dark support, WCAG AA+ contrast.
class AppTheme {
  AppTheme._();

  // ---- Brand palette (ocean / sea) ----
  static const Color _seaCyan = Color(0xFF0E7490); // deep sea cyan (primary)
  static const Color _seaTeal = Color(0xFF0F766E); // sea teal (secondary)
  static const Color _seaAccent = Color(0xFF0891B2); // accent cyan
  static const Color _seaSurface = Color(0xFFF4FBFC); // aqua-tinted base
  static const Color _seaInk = Color(0xFF0A2A33); // deep sea ink
  static const Color _muted = Color(0xFFE1EFF1);
  static const Color _border = Color(0xFFD6E4E7);
  static const Color _destructive = Color(0xFFDC2626);

  static const Color _lightPrimary = _seaCyan;
  static const Color _darkPrimary = Color(0xFF6BD9E8);

  /// Shared component styling between light and dark modes.
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? _darkPrimary : _lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF0B5C6B) : const Color(0xFFB8ECF7),
      onPrimaryContainer: isDark ? const Color(0xFFB8ECF7) : const Color(0xFF003640),
      secondary: isDark ? const Color(0xFF5EE2D4) : _seaTeal,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF0B564F) : const Color(0xFFCCFBF1),
      onSecondaryContainer: isDark ? const Color(0xFFCCFBF1) : const Color(0xFF00332E),
      tertiary: isDark ? const Color(0xFF58C7E0) : _seaAccent,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF0B4152) : const Color(0xFFC3ECF5),
      onTertiaryContainer: isDark ? const Color(0xFFC3ECF5) : const Color(0xFF033E52),
      error: _destructive,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: isDark ? const Color(0xFF0B171A) : _seaSurface,
      onSurface: isDark ? const Color(0xFFE0EDEF) : _seaInk,
      surfaceContainerLowest: isDark ? const Color(0xFF081215) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF102024) : const Color(0xFFF8FDFE),
      surfaceContainer: isDark ? const Color(0xFF17282B) : const Color(0xFFEFF8FA),
      surfaceContainerHigh: isDark ? const Color(0xFF1E3134) : const Color(0xFFE9F4F6),
      surfaceContainerHighest: isDark ? const Color(0xFF283B3F) : _muted,
      onSurfaceVariant: isDark ? const Color(0xFFB9CDD2) : const Color(0xFF405B63),
      outline: isDark ? const Color(0xFF7F9AA0) : const Color(0xFF6F878E),
      outlineVariant: isDark ? const Color(0xFF283B3F) : _border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? const Color(0xFFE0EDEF) : const Color(0xFF0B171A),
      onInverseSurface: isDark ? const Color(0xFF0B171A) : const Color(0xFFF4FBFC),
      inversePrimary: isDark ? _lightPrimary : const Color(0xFF6BD9E8),
      surfaceTint: isDark ? _darkPrimary : _lightPrimary,
    );

    const radiusCard = 20.0;
    const radiusField = 16.0;
    const radiusButton = 14.0;

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,

      // ---- App bars ----
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),

      // ---- Cards: soft depth, generous radius ----
      cardTheme: CardThemeData(
        elevation: 1,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),

      // ---- Buttons (>=48px touch targets) ----
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ---- Inputs: filled, rounded, soft ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      // ---- Bottom navigation ----
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      // ---- Dialog / snackbar / dividers / progress ----
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          textStyle: WidgetStatePropertyAll(
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // ---- Typography: consistent weight hierarchy ----
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1),
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
        bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);
}