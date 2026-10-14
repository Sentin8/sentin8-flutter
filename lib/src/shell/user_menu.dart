// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../bff_auth/auth_provider.dart';

/// User menu widget shown at the bottom of the sidebar.
/// Displays the user's avatar, name/email, and a sign-out button.
class UserMenu extends StatelessWidget {
  final BffAuthProvider auth;

  const UserMenu({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Sentin8Colors.primary,
        child: Text(
          user?.displayName?.isNotEmpty == true
              ? user!.displayName![0].toUpperCase()
              : user?.email.isNotEmpty == true
                  ? user!.email[0].toUpperCase()
                  : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(user?.displayName ?? user?.email ?? 'User', style: Sentin8Text.bodyMedium),
      trailing: IconButton(
        icon: const Icon(Icons.logout, color: Sentin8Colors.textSecondary),
        onPressed: () => auth.signOut(),
        tooltip: 'Sign Out',
      ),
    );
  }
}