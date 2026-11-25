// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF auth transport - browser implementation.
//
// Reached only through `auth_transport.dart`'s conditional export.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

/// `GET {bffBaseUrl}/auth/session` with cookies.
///
/// Returns the raw response body on 200, or null for any other status.
///
/// [sessionToken] exists for signature parity with the IO implementation and is
/// ignored: the browser's credential is the HttpOnly session cookie, which
/// `credentials: 'include'` sends automatically. Accepting it here means the
/// shared call site in `auth_provider.dart` needs no platform branch.
Future<String?> fetchSessionJson(String bffBaseUrl, {String? sessionToken}) async {
  final response = await web.window.fetch(
    '$bffBaseUrl/auth/session'.toJS,
    web.RequestInit(method: 'GET', credentials: 'include'),
  ).toDart;
  if (response.status != 200) return null;
  return (await response.text().toDart).toDart;
}

/// `POST {bffBaseUrl}/auth/sign-out` with cookies and the CSRF header.
///
/// [sessionToken] is accepted for signature parity and ignored (see
/// [fetchSessionJson]).
Future<void> postSignOut(
  String bffBaseUrl,
  String? csrfToken, {
  String? sessionToken,
}) async {
  final h = web.Headers();
  h.set('Accept', 'application/json');
  h.set('Content-Type', 'application/json');
  if (csrfToken != null) h.set('X-BFF-CSRF', csrfToken);
  await web.window.fetch(
    '$bffBaseUrl/auth/sign-out'.toJS,
    web.RequestInit(
      method: 'POST',
      credentials: 'include',
      headers: h,
      body: '{}'.toJS,
    ),
  ).toDart;
}
