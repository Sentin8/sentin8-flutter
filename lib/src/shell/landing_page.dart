// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../theme/glass_panel.dart';
import '../theme/logo.dart';
import '../bootstrap/runtime_context.dart';
import '../bff_auth/auth_provider.dart';

/// Landing page shown when the user is not signed in.
/// Provides Sign In and Sign Up buttons that redirect to Auth hosted UI.
///
/// [welcomeText] overrides the default "Welcome to {displayName}" heading.
/// [descriptionText] overrides the default instance description.
/// [defaultIcon] is shown when no logo URL is available.
/// [onSignIn] and [onSignUp] override the default redirect behavior.
class LandingPage extends StatelessWidget {
  final AppRuntimeContext runtimeContext;
  final BffAuthProvider auth;
  final String? welcomeText;
  final String? descriptionText;
  final IconData defaultIcon;

  const LandingPage({
    super.key,
    required this.runtimeContext,
    required this.auth,
    this.welcomeText,
    this.descriptionText,
    this.defaultIcon = Icons.account_balance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sentin8Colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: GlassPanel(
              padding: const EdgeInsets.all(Sentin8Spacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (runtimeContext.logoIconUrl.isNotEmpty)
                      networkLogo(
                        runtimeContext.logoIconUrl,
                        size: 64,
                        fallbackWidget: Icon(defaultIcon, size: 64, color: Sentin8Colors.primary),
                      )
                    else if (runtimeContext.logoUrl.isNotEmpty)
                      networkLogo(
                        runtimeContext.logoUrl,
                        size: 64,
                        fallbackWidget: Icon(defaultIcon, size: 64, color: Sentin8Colors.primary),
                      )
                    else
                      Icon(defaultIcon, size: 64, color: Sentin8Colors.primary),
                    const SizedBox(height: Sentin8Spacing.lg),
                    Text(
                      welcomeText ?? 'Welcome to ${runtimeContext.displayName}',
                      style: Sentin8Text.headlineLarge,
                    ),
                    const SizedBox(height: Sentin8Spacing.sm),
                    Text(
                      descriptionText ?? (runtimeContext.instanceDescription.isNotEmpty
                          ? runtimeContext.instanceDescription
                          : 'Sign in to continue.'),
                      style: Sentin8Text.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sentin8Spacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => auth.signInWithAuth(),
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: Sentin8Spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => auth.signUpWithAuth(),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}