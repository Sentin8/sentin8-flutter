// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../theme/glass_panel.dart';

/// Bootstrap error page shown when runtime context resolution fails.
/// Fail-closed: if the hostname is unknown or the API key is invalid,
/// the app cannot proceed.
/// [appName] is displayed in the error message (e.g. 'Unable to start eBank').
class BootstrapErrorPage extends StatelessWidget {
  final String error;
  final String appName;

  const BootstrapErrorPage({super.key, required this.error, this.appName = 'App'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sentin8Colors.background,
      body: Center(
        child: GlassPanel(
          padding: const EdgeInsets.all(Sentin8Spacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Sentin8Colors.error),
                const SizedBox(height: Sentin8Spacing.lg),
                Text('Unable to start $appName', style: Sentin8Text.headlineMedium),
                const SizedBox(height: Sentin8Spacing.md),
                Text(
                  'The application could not resolve its runtime context. '
                  'This may be due to an unknown hostname or missing configuration.',
                  style: Sentin8Text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Sentin8Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Sentin8Spacing.sm),
                  decoration: BoxDecoration(
                    color: Sentin8Colors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    error,
                    style: Sentin8Text.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}