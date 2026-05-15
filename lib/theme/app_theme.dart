import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // ─── Dark Theme Colors ───────────────────────────────────────────
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1A2235);
  static const Color cardBorder = Color(0xFF2A3550);

  // ─── Light Theme Colors ──────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF0F4FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFCDD5E0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF64748B);

  // ─── Brand Colors ────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F7FFF);
  static const Color primaryDark = Color(0xFF3A6AE8);
  static const Color primaryLight = Color(0xFF7BA3FF);
  static const Color accent = Color(0xFF00C49A);
  static const Color accentGlow = Color(0x3300C49A);
  static const Color connected = Color(0xFF00C49A);
  static const Color disconnected = Color(0xFF6B7280);

  // ─── Status Colors ───────────────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // ─── Dark Text Colors ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);

  // ─── Ping Quality Colors ─────────────────────────────────────────
  static const Color pingGood = Color(0xFF10B981);
  static const Color pingMedium = Color(0xFFF59E0B);
  static const Color pingBad = Color(0xFFEF4444);

  // ─── Helper: tema'ya göre renk seç ──────────────────────────────
  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimary
        : lightTextPrimary;
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondary
        : lightTextSecondary;
  }

  static Color cardOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? card : lightCard;
  }

  static Color cardBorderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBorder
        : lightCardBorder;
  }

  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? background
        : lightBackground;
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onSurface: AppColors.lightTextPrimary,
        onBackground: AppColors.lightTextPrimary,
      ),
      fontFamily: 'Roboto',
      // Tüm metin stilleri açık temada koyu renk
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.lightTextPrimary,
            displayColor: AppColors.lightTextPrimary,
          ).copyWith(
            displayLarge: const TextStyle(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            bodyLarge: const TextStyle(color: AppColors.lightTextPrimary),
            bodyMedium: const TextStyle(color: AppColors.lightTextSecondary),
            bodySmall: const TextStyle(color: AppColors.lightTextMuted),
            titleLarge: const TextStyle(
                color: AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold),
            titleMedium: const TextStyle(color: AppColors.lightTextPrimary),
            titleSmall: const TextStyle(color: AppColors.lightTextSecondary),
            labelLarge: const TextStyle(color: AppColors.lightTextPrimary),
            labelMedium: const TextStyle(color: AppColors.lightTextSecondary),
            labelSmall: const TextStyle(color: AppColors.lightTextMuted),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        foregroundColor: AppColors.lightTextPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightCardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.lightCardBorder;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightCardBorder,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.lightTextPrimary,
        iconColor: AppColors.lightTextSecondary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: AppColors.lightTextPrimary),
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStateProperty.all(AppColors.lightCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted),
        prefixIconColor: AppColors.lightTextSecondary,
        suffixIconColor: AppColors.lightTextSecondary,
      ),
      cardTheme: CardTheme(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightCardBorder),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightCard,
        titleTextStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle:
            const TextStyle(color: AppColors.lightTextSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: TextStyle(color: AppColors.lightBackground),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ).copyWith(
            displayLarge: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            bodyLarge: const TextStyle(color: AppColors.textPrimary),
            bodyMedium: const TextStyle(color: AppColors.textSecondary),
            bodySmall: const TextStyle(color: AppColors.textMuted),
            titleLarge: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            titleMedium: const TextStyle(color: AppColors.textPrimary),
            titleSmall: const TextStyle(color: AppColors.textSecondary),
            labelLarge: const TextStyle(color: AppColors.textPrimary),
            labelMedium: const TextStyle(color: AppColors.textSecondary),
            labelSmall: const TextStyle(color: AppColors.textMuted),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary),
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.cardBorder;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.card,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
