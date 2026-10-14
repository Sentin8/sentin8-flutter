// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';
import '../bootstrap/runtime_context.dart';

/// Default light theme.
ThemeData sentin8Theme() => _sentin8Theme(
  Sentin8Colors.primary, Sentin8Colors.primary, Brightness.light,
);

/// Default dark theme.
ThemeData sentin8DarkTheme() => _sentin8DarkTheme(
  Sentin8Colors.primary, Sentin8Colors.primary,
);

/// Tenant-branded light theme from [AppRuntimeContext].
ThemeData sentin8ThemeForContext(AppRuntimeContext ctx) {
  final primary = Sentin8Colors.parseHex(ctx.primaryColor) ?? Sentin8Colors.primary;
  final accent = Sentin8Colors.parseHex(ctx.accentColor) ?? primary;
  if (ctx.themeMode == 'dark') return _sentin8DarkTheme(primary, accent);
  return _sentin8Theme(primary, accent, Brightness.light);
}

/// Tenant-branded dark theme from [AppRuntimeContext].
ThemeData sentin8DarkThemeForContext(AppRuntimeContext ctx) {
  final primary = Sentin8Colors.parseHex(ctx.primaryColor) ?? Sentin8Colors.primary;
  final accent = Sentin8Colors.parseHex(ctx.accentColor) ?? primary;
  return _sentin8DarkTheme(primary, accent);
}

ThemeData _sentin8Theme(Color primary, Color accent, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Sentin8Colors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Sentin8Colors.surface, elevation: 0,
      foregroundColor: Sentin8Colors.textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Sentin8Colors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Sentin8Colors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Sentin8Colors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: Sentin8Text.headlineLarge,
      headlineMedium: Sentin8Text.headlineMedium,
      bodyLarge: Sentin8Text.bodyLarge,
      bodyMedium: Sentin8Text.bodyMedium,
      labelSmall: Sentin8Text.labelSmall,
    ),
  );
}

ThemeData _sentin8DarkTheme(Color primary, Color accent) {
  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Sentin8ColorsDark.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Sentin8ColorsDark.surface, elevation: 0,
      foregroundColor: Sentin8ColorsDark.textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Sentin8ColorsDark.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Sentin8ColorsDark.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Sentin8ColorsDark.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: Sentin8Text.headlineLarge.copyWith(color: Sentin8ColorsDark.textPrimary),
      headlineMedium: Sentin8Text.headlineMedium.copyWith(color: Sentin8ColorsDark.textPrimary),
      bodyLarge: Sentin8Text.bodyLarge.copyWith(color: Sentin8ColorsDark.textPrimary),
      bodyMedium: Sentin8Text.bodyMedium.copyWith(color: Sentin8ColorsDark.textPrimary),
      labelSmall: Sentin8Text.labelSmall.copyWith(color: Sentin8ColorsDark.textSecondary),
    ),
  );
}

