// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF proxy client - native transport (Android / iOS / desktop).
//
// There is no ambient cookie jar on the VM, so this sends the opaque session
// token as `Authorization: Bearer <token>` (see the WS1 design: the BFF accepts
// a bearer session as an alternative to the `bff-session` cookie). Every other
// header - correlation id, CSRF, delegation - comes from the shared core.
//
// Reached only through `bff_client.dart`'s conditional export.

import 'dart:convert';
import 'dart:io';

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
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, url);
      headers?.forEach(request.headers.set);
      if (body != null) {
        request.headers.contentLength = body.length;
        request.write(body);
      }
      final response = await request.close();
      final raw = await response.transform(const Utf8Decoder()).join();
      return ApiResponse.fromStatusBody(response.statusCode, raw);
    } finally {
      client.close();
    }
  }
}
