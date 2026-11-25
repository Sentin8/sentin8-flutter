// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// Runtime-context hostname source - browser implementation.

// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

/// Resolve the `X-Sentin8-Hostname` value.
///
/// An explicit [hostname] always wins (a caller may know better than the
/// address bar, e.g. when bootstrapping a different instance). Otherwise the
/// browser's own host is used.
///
/// Throws [StateError] when neither is available - never returns a default.
String resolveHostname(String? hostname) {
  if (hostname != null && hostname.isNotEmpty) return hostname;

  final host = web.window.location.hostname;
  if (host.isEmpty) {
    throw StateError('Cannot resolve the runtime-context hostname: '
        'window.location.hostname is empty and no hostname was supplied.');
  }
  return host;
}
