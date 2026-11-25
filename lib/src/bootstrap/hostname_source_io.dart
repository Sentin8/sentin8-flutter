// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// Runtime-context hostname source - native (Android / iOS / desktop).
//
// A native app has no address bar, so the instance host must come from the
// caller - normally the origin persisted at enrollment. There is deliberately
// no fallback: the pre-split `'localhost'` default meant a misconfigured native
// bootstrap looked like a valid localhost instance instead of failing.

/// Resolve the `X-Sentin8-Hostname` value from the caller-supplied host.
///
/// Throws [StateError] when [hostname] is null or empty. Callers should treat
/// that as "the app is not enrolled yet" and show the pairing screen.
String resolveHostname(String? hostname) {
  if (hostname == null || hostname.isEmpty) {
    throw StateError('The runtime-context hostname is required on native: '
        'supply the instance host established at enrollment. An unenrolled '
        'app should show the pairing screen, not attempt a bootstrap.');
  }
  return hostname;
}
