// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF auth transport - native implementation (Android / iOS / desktop).
//
// No ambient cookie jar exists on the VM, so identity rides
// `Authorization: Bearer <sessionToken>` - the opaque session credential from
// the native handoff (WS1), never an OAuth access token.
//
// Reached only through `auth_transport.dart`'s conditional export.

import 'dart:convert';
import 'dart:io';

/// `GET {bffBaseUrl}/auth/session`.
///
/// Returns the raw response body on 200, or null for any other status.
Future<String?> fetchSessionJson(
  String bffBaseUrl, {
  String? sessionToken,
}) async {
  final client = HttpClient();
  try {
    final request =
        await client.getUrl(Uri.parse('$bffBaseUrl/auth/session'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (sessionToken != null && sessionToken.isNotEmpty) {
      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $sessionToken');
    }
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    if (response.statusCode != HttpStatus.ok) return null;
    return body;
  } finally {
    client.close();
  }
}

/// `POST {bffBaseUrl}/auth/sign-out`.
Future<void> postSignOut(
  String bffBaseUrl,
  String? csrfToken, {
  String? sessionToken,
}) async {
  final client = HttpClient();
  try {
    final request =
        await client.postUrl(Uri.parse('$bffBaseUrl/auth/sign-out'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    if (csrfToken != null) request.headers.set('X-BFF-CSRF', csrfToken);
    if (sessionToken != null && sessionToken.isNotEmpty) {
      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $sessionToken');
    }
    request.write('{}');
    final response = await request.close();
    await response.drain<void>();
  } finally {
    client.close();
  }
}
