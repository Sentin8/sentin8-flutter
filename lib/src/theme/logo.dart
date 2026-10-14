// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a network logo image. SVG URLs are rendered via
/// [SvgPicture.network] (CanvasKit can't decode SVGs via Image.network).
/// Raster URLs (PNG, JPG, etc.) use [Image.network].
/// Falls back to [fallbackWidget] on error.
Widget networkLogo(String url,
    {required double size, required Widget fallbackWidget}) {
  if (url.toLowerCase().endsWith('.svg')) {
    return SvgPicture.network(
      url,
      height: size,
      placeholderBuilder: (context) => SizedBox(
        height: size,
        width: size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorBuilder: (context, error, stackTrace) => fallbackWidget,
    );
  }
  return Image.network(
    url,
    height: size,
    errorBuilder: (context, error, stackTrace) => fallbackWidget,
  );
}

/// Maps a Ledger productType string to the Material icon shown for that
/// product (and for any account opened from that product). Centralized
/// so the icon shown on a product card matches the icon shown on the
/// account list/dashboard rows for that product.
IconData productIconForType(String? type) {
  return switch (type) {
    'current_account' || 'us_checking' => Icons.account_balance_wallet,
    'savings_account' || 'us_savings' || 'shariah_savings' => Icons.savings,
    'credit_card' => Icons.credit_card,
    'loan' || 'mortgage' || 'home_loan_redraw' || 'line_of_credit' =>
      Icons.home_work,
    'time_deposit' => Icons.lock_clock,
    'wallet' => Icons.wallet,
    'bnpl' => Icons.shopping_bag,
    _ => Icons.account_balance,
  };
}