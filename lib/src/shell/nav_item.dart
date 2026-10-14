// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Navigation item for the sidebar.
class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;
  final ValueChanged<String> onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == route;
    return ListTile(
      leading: Icon(icon, color: isActive ? Sentin8Colors.primary : Sentin8Colors.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Sentin8Colors.primary : Sentin8Colors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isActive,
      selectedTileColor: Sentin8Colors.primary.withValues(alpha: 0.08),
      onTap: () => onTap(route),
    );
  }
}