// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Access denied page shown when a user lacks permission for a page.
class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Sentin8Colors.error),
            SizedBox(height: Sentin8Spacing.md),
            Text('Access Denied', style: Sentin8Text.headlineMedium),
            SizedBox(height: Sentin8Spacing.sm),
            Text('You do not have permission to access this page.',
                style: Sentin8Text.bodyMedium),
          ],
        ),
      ),
    );
  }
}