// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import 'dart:math';

/// Generate a correlation ID for request tracing.
/// Propagated as x-sentin8-correlation-id header (SDK8 §3.9 requirement).
/// [prefix] is a short app identifier (e.g. 'ebk', 'etl', 'efn').
///
/// Includes a random component: callers in a tight loop can share one
/// millisecond timestamp, and a timestamp-only ID would collide (breaking
/// request tracing). 6 base-36 random chars give ~2.2 billion combinations.
String generateCorrelationId({String prefix = 'app'}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final rand = Random();
  final suffix = List.generate(
    6,
    (_) => rand.nextInt(36).toRadixString(36),
  ).join();
  return '$prefix-$now-$suffix';
}
