// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF proxy client - browser transport.
//
// Uses `window.fetch` with `credentials: 'include'` so the BFF's HttpOnly
// session cookie rides every request. Reached only through `bff_client.dart`'s
// conditional export.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

import 'bff_client_core.dart';

class BffApiClient extends BffApiClientBase {
  BffApiClient({
    required super.bffBaseUrl,
    required super.serviceName,
    super.csrfToken,
    super.correlationId,
    super.delegationId,
    super.sessionToken,
  });

  @override
  Future<ApiResponse> sendRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final requestHeaders = web.Headers();
    // NOTE: `requestHeaders.set` cannot be torn off (dart2js rejects
    // tear-offs of external extension-type interop members), so call it
    // explicitly rather than passing it to forEach.
    headers?.forEach((key, value) {
      requestHeaders.set(key, value);
    });

    final init = web.RequestInit(
      method: method,
      credentials: 'include',
      headers: requestHeaders,
      body: body != null ? body.toJS : null,
    );

    final response =
        await web.window.fetch(url.toString().toJS, init).toDart;
    final raw = (await response.text().toDart).toDart;
    return ApiResponse.fromStatusBody(response.status, raw);
  }
}
