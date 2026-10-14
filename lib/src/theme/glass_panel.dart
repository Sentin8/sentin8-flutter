// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';

/// A frosted-glass-style panel used as the base container for cards and
/// landing-page forms. Provides a subtle border and shadow.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sentin8Spacing.lg),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Sentin8Colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Sentin8Colors.border),
        boxShadow: [
          BoxShadow(
            color: Sentin8Colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}