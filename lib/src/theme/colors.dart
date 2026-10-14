// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

/// Sentin8 design-system color palette (light theme).
class Sentin8Colors {
  static const primary = Color(0xFF1A56DB);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF1E40AF);
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFFF8FAFC);
  static const background = Color(0xFFF1F5F9);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const border = Color(0xFFE2E8F0);
  static const glass = Color(0x88FFFFFF);

  // Sentin8 brand colors (used by RFW renderer).
  static const carbonBlack = Color(0xFF111111);
  static const royalGold = Color(0xFFD4AF37);
  static const errorCrimson = Color(0xFFD64545);

  /// Parse a hex color string (e.g. "#1E6BFF") to a Color.
  /// Returns null if the string is empty or invalid.
  static Color? parseHex(String hex) {
    if (hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}

/// Dark theme color overrides.
class Sentin8ColorsDark {
  static const surface = Color(0xFF0A0A0A);
  static const surfaceDark = Color(0xFF111111);
  static const background = Color(0xFF0A0A0A);
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFFA0A0A0);
  static const border = Color(0xFF333333);
  static const error = Color(0xFFD64545);
}