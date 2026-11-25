// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// URL hash router - IO (Android / iOS / desktop) implementation.
//
// Deliberately a no-op set. A native app has no address bar and no URL hash,
// so "route" is ordinary widget state. Keeping the same five functions - with
// the same signatures - means app code that already calls `navigateTo(...)`
// keeps compiling and simply loses the browser-URL side effect.
//
// This preserves the pre-split behaviour exactly: every function here used to
// begin with `if (!kIsWeb) return;`, so the observable behaviour on native was
// already "do nothing". The difference is that the web-only import no longer
// has to be compiled for the VM.
//
// Native back-button behaviour is a widget concern (`PopScope` /
// `NavigatorObserver`) and is handled in the app, not here - see the WS3
// design, `02-flutter-sdk-platformization.md` §3.2.
//
// This file must only be reached through `url_router.dart`'s conditional
// export - never imported directly.

/// No-op on native: the browser URL hash does not exist.
void navigateTo(String route) {}

/// No-op on native: history entries are the platform's job.
void pushRoute(String route) {}

/// No-op on native: use `Navigator.pop` / `PopScope` instead.
void goBack() {}

/// No-op on native: there is no hash to read, so the app's own routing state
/// is the single source of truth.
String currentRoute() => '/';
