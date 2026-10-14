// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// URL hash router utility.
//
// Provides global helpers for updating the browser URL hash from any
// widget (sidebar nav, in-page item clicks, back button). Pages call
// `navigateTo('/messages/123')` and the address bar updates.
//
// The app shell reads the initial route from the hash on startup and
// listens to popstate for browser back/forward.

import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

/// Update the browser URL hash to reflect the current page/view.
/// Uses `replaceState` so it doesn't add a new history entry on every
/// click (avoids back-button spam within a single page).
void navigateTo(String route) {
  if (!kIsWeb) return;
  web.window.history.replaceState(null, '', '#$route');
}

/// Push a new history entry (for sub-page navigation like message detail
/// so the browser back button returns to the list).
void pushRoute(String route) {
  if (!kIsWeb) return;
  web.window.history.pushState(null, '', '#$route');
}

/// Go back in browser history.
void goBack() {
  if (!kIsWeb) return;
  web.window.history.back();
}

/// Get the current route from the URL hash.
String currentRoute() {
  if (!kIsWeb) return '/';
  final hash = web.window.location.hash;
  if (hash.isNotEmpty && hash.startsWith('#')) {
    final route = hash.substring(1);
    return route.isEmpty ? '/' : route;
  }
  return '/';
}