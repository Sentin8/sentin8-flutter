// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

/// Parse a balance value from an account map. The Ledger API returns
/// `currentBalance` as a string in minor units (e.g. "50000" = $500.00).
/// This helper handles both string and numeric values and converts
/// to major units for display.
double parseBalance(Map<String, dynamic> account) {
  final val = account['currentBalance'] ?? account['current_balance'] ?? account['balance'];
  if (val == null) return 0;
  double minor;
  if (val is num) {
    minor = val.toDouble();
  } else if (val is String) {
    minor = double.tryParse(val) ?? 0;
  } else {
    return 0;
  }
  // Convert minor units to major units (e.g. 50000 cents → 500.00)
  return minor / 100;
}

/// Convert major units to minor units string.
/// e.g. "500.00" → "50000"
String toMinorUnits(String majorAmount) {
  final major = double.tryParse(majorAmount);
  if (major == null || major <= 0) return '0';
  return (major * 100).round().toString();
}

/// Money input formatter regex - allows digits with up to 2 decimal places.
final moneyInputRegex = RegExp(r'^\d*\.?\d{0,2}');