// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF proxy access layer - shared core.
//
// All backend communication goes through BFF proxy routes. The client holds
// either a session cookie (browser) or an opaque session token (native) - never
// an OAuth token; the BFF attaches the real access token server-side.
//
// This file owns everything platform-neutral: URL composition, header maps,
// query merging, the response envelope rules, and [ApiResponse]. The transports
// live in `bff_client_web.dart` (window.fetch) and `bff_client_io.dart`
// (dart:io HttpClient), so the two cannot drift on the wire contract.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../bff/correlation.dart';

/// Response from a BFF-proxied API call.
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? error;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.error,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Build a response from a raw body, applying the platform-neutral envelope
  /// rules. Shared by both transports so their parsing cannot diverge.
  factory ApiResponse.fromStatusBody(int statusCode, String raw) {
    if (raw.isEmpty) {
      return ApiResponse(statusCode: statusCode);
    }
    Object? body;
    try {
      body = jsonDecode(raw);
    } catch (_) {
      body = raw;
    }
    if (body is Map<String, dynamic>) {
      // Unwrap the {success, data} envelope when present.
      if (body.containsKey('success') && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ApiResponse(statusCode: statusCode, data: data);
      }
      return ApiResponse(statusCode: statusCode, data: body);
    }
    // Services may return a bare JSON array (no envelope). Wrap it in
    // `{'data': body}` so callers can read it via `response.data!['data']`.
    if (body is List<dynamic>) {
      return ApiResponse(statusCode: statusCode, data: {'data': body});
    }
    return ApiResponse(statusCode: statusCode, error: raw);
  }

  factory ApiResponse.fromHttp(http.Response response) {
    return ApiResponse.fromStatusBody(response.statusCode, response.body);
  }
}

/// Platform-neutral base for the BFF proxy client.
///
/// Holds the wiring every transport shares and leaves exactly two hooks to the
/// implementation: [sendRequest] (perform one verb) and nothing else.
abstract class BffApiClientBase {
  final String bffBaseUrl;
  final String serviceName;
  final String? csrfToken;
  final String? correlationId;

  /// §4.3f (Option A): active CIBA delegation session id (from BFF
  /// `POST /delegate/start`). When set, every request carries
  /// `X-BFF-Delegation` so the BFF attaches the customer-approved,
  /// time-boxed delegated token instead of the caller's own session token.
  final String? delegationId;

  /// Opaque BFF session credential for the native transport.
  ///
  /// The browser transport authenticates with the session cookie and ignores
  /// this. Never an OAuth access token - see the note at the top of the file.
  final String? sessionToken;

  BffApiClientBase({
    required this.bffBaseUrl,
    required this.serviceName,
    this.csrfToken,
    this.correlationId,
    this.delegationId,
    this.sessionToken,
  });

  /// Build the full proxy URL for a given path.
  /// e.g. /accounts → https://{bff}/proxy/ledger/accounts
  ///
  /// The org/env is NOT appended as query params - the BFF proxy resolves the
  /// target org/env from the TLS-injected X-Sentin8-Env-Id header (which comes
  /// from the request hostname). Adding target_org_id/target_env_id would
  /// trigger BFF token delegation, which requires the user to be a member of
  /// the target org via direct role assignment (not group membership). The TLS
  /// context is sufficient.
  String buildUrl(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$bffBaseUrl/proxy/$serviceName$cleanPath';
  }

  /// The header set every request carries.
  Map<String, String> headers({bool mutating = false}) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (correlationId != null) 'x-sentin8-correlation-id': correlationId!,
      if (mutating && csrfToken != null) 'X-BFF-CSRF': csrfToken!,
      if (delegationId != null) 'X-BFF-Delegation': delegationId!,
      if (sessionToken != null && sessionToken!.isNotEmpty)
        'Authorization': 'Bearer $sessionToken',
    };
  }

  /// Perform one request. Implemented per platform.
  Future<ApiResponse> sendRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    String? body,
  });

  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) {
    var url = Uri.parse(buildUrl(path));
    if (queryParams != null) {
      url = url.replace(
          queryParameters: {...url.queryParameters, ...queryParams});
    }
    return sendRequest('GET', url, headers: headers());
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) {
    return sendRequest(
      'POST',
      Uri.parse(buildUrl(path)),
      headers: headers(mutating: true),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) {
    return sendRequest(
      'PUT',
      Uri.parse(buildUrl(path)),
      headers: headers(mutating: true),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<ApiResponse> delete(String path) {
    return sendRequest(
      'DELETE',
      Uri.parse(buildUrl(path)),
      headers: headers(mutating: true),
    );
  }
}

/// Stable correlation id for the current client/session.
///
/// Re-exported so callers keep the pre-split import path.
String newCorrelationId() => generateCorrelationId();
