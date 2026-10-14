// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Notification bell widget for the sidebar.
/// Shows the unread message count as a badge.
class NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const NotificationBell({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sentin8Spacing.lg, vertical: Sentin8Spacing.sm),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: Sentin8Colors.primary, size: 20),
            const SizedBox(width: Sentin8Spacing.sm),
            Text('Messages', style: Sentin8Text.bodyMedium.copyWith(color: Sentin8Colors.primary)),
            const Spacer(),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Sentin8Colors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}