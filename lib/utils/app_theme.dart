import 'package:flutter/material.dart';

class AppTheme {
  static const brand = Color(0xFF4338CA); // Indigo 700

  static ThemeData light() => _build(
        ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.light).copyWith(
          primary: brand,
          surface: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF8FAFC),
          surfaceContainer: const Color(0xFFF1F5F9),
          surfaceContainerHigh: const Color(0xFFE2E8F0),
          outlineVariant: const Color(0xFFE2E8F0),
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF64748B),
        ),
        scaffold: const Color(0xFFF6F7FB),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark).copyWith(
          primary: const Color(0xFFA5B4FC),
          onPrimary: const Color(0xFF1E1B4B),
          surface: const Color(0xFF151A26),
          surfaceContainerLowest: const Color(0xFF0E121B),
          surfaceContainerLow: const Color(0xFF1A2030),
          surfaceContainer: const Color(0xFF1F2637),
          surfaceContainerHigh: const Color(0xFF283044),
          outlineVariant: const Color(0xFF2A3245),
          onSurface: const Color(0xFFE2E8F0),
          onSurfaceVariant: const Color(0xFF94A3B8),
        ),
        scaffold: const Color(0xFF0E121B),
      );

  static ThemeData _build(ColorScheme scheme, {required Color scaffold}) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: scheme.brightness);
    final radius = BorderRadius.circular(12);
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: scheme.outlineVariant)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.error)),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: scheme.outlineVariant)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    );
  }
}
