// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Bootstrap loader page shown while fetching runtime context.
/// [appName] is displayed in the loading message (e.g. 'Starting eBank...').
class BootstrapLoaderPage extends StatelessWidget {
  final String appName;

  const BootstrapLoaderPage({super.key, this.appName = 'App'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sentin8Colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, size: 48, color: Sentin8Colors.primary),
            const SizedBox(height: Sentin8Spacing.lg),
            Text('Starting $appName...', style: Sentin8Text.headlineMedium),
            const SizedBox(height: Sentin8Spacing.md),
            const CircularProgressIndicator(color: Sentin8Colors.primary),
          ],
        ),
      ),
    );
  }
}