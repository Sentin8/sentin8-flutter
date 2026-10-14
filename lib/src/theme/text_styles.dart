// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'colors.dart';

/// Sentin8 preset text styles.
class Sentin8Text {
  const Sentin8Text._();

  static const headlineLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: Sentin8Colors.textPrimary, height: 1.2,
  );
  static const headlineMedium = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w600,
    color: Sentin8Colors.textPrimary, height: 1.3,
  );
  static const bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: Sentin8Colors.textPrimary, height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: Sentin8Colors.textPrimary, height: 1.5,
  );
  static const labelSmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: Sentin8Colors.textSecondary, height: 1.4,
  );
}