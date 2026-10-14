// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF proxy access layer — generic API client for all Sentin8 apps.
//
// All backend communication goes through BFF proxy routes.
// The Flutter app only sends its session token (cookie-based on web).
// BFF attaches the Auth access token server-side.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// API client that routes all requests through BFF proxy.
///
/// [bffBaseUrl] is the per-instance BFF domain
/// [serviceName] is the target service (ledger, payments, fdx, db, buck, post)
/// [csrfToken] is the BFF CSRF token for web mutating requests
class BffApiClient {
  final String bffBaseUrl;
  final String serviceName;
  final String? csrfToken;
  final String? correlationId;
  /// §4.3f (Option A): active CIBA delegation session id (from BFF
  /// `POST /delegate/start`). When set, every request carries
  /// `X-BFF-Delegation` so the BFF attaches the customer-approved,
  /// time-boxed delegated token instead of the caller's own session token.
  /// Staff/customer-data access ALWAYS goes through this — never a
  /// standing staff scope.
  final String? delegationId;

  BffApiClient({
    required this.bffBaseUrl,
    required this.serviceName,
    this.csrfToken,
    this.correlationId,
    this.delegationId,
  });

  /// Build the full proxy URL for a given path.
  /// e.g. /accounts → https://{bff}/proxy/ledger/accounts
  ///
  /// The org/env is NOT appended as query params — the BFF proxy
  /// resolves the target org/env from the TLS-injected X-Sentin8-Env-Id
  /// header (which comes from the request hostname).
  /// Adding target_org_id/target_env_id would trigger BFF token delegation,
  /// which requires the user to be a member of the target org via direct
  /// role assignment (not group membership). The TLS context is sufficient.
  String _buildUrl(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$bffBaseUrl/proxy/$serviceName$cleanPath';
  }

  Map<String, String> _headers({bool mutating = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (correlationId != null) 'x-sentin8-correlation-id': correlationId!,
      if (mutating && csrfToken != null) 'X-BFF-CSRF': csrfToken!,
      if (delegationId != null) 'X-BFF-Delegation': delegationId!,
    };
    return headers;
  }

  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    var url = Uri.parse(_buildUrl(path));
    if (queryParams != null) {
      url = url.replace(queryParameters: {...url.queryParameters, ...queryParams});
    }
    if (kIsWeb) {
      final response = await web.window.fetch(
        url.toString().toJS,
        web.RequestInit(method: 'GET', credentials: 'include', headers: _webHeaders()),
      ).toDart;
      return _webResponseToApi(response);
    }
    final response = await http.get(url, headers: _headers());
    return ApiResponse.fromHttp(response);
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    if (kIsWeb) {
      final response = await web.window.fetch(
        _buildUrl(path).toJS,
        web.RequestInit(
          method: 'POST',
          credentials: 'include',
          headers: _webHeaders(mutating: true),
          body: body != null ? jsonEncode(body).toJS : '{}'.toJS,
        ),
      ).toDart;
      return _webResponseToApi(response);
    }
    final response = await http.post(
      Uri.parse(_buildUrl(path)),
      headers: _headers(mutating: true),
      body: body != null ? jsonEncode(body) : null,
    );
    return ApiResponse.fromHttp(response);
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    if (kIsWeb) {
      final response = await web.window.fetch(
        _buildUrl(path).toJS,
        web.RequestInit(
          method: 'PUT',
          credentials: 'include',
          headers: _webHeaders(mutating: true),
          body: body != null ? jsonEncode(body).toJS : '{}'.toJS,
        ),
      ).toDart;
      return _webResponseToApi(response);
    }
    final response = await http.put(
      Uri.parse(_buildUrl(path)),
      headers: _headers(mutating: true),
      body: body != null ? jsonEncode(body) : null,
    );
    return ApiResponse.fromHttp(response);
  }

  Future<ApiResponse> delete(String path) async {
    if (kIsWeb) {
      final response = await web.window.fetch(
        _buildUrl(path).toJS,
        web.RequestInit(
          method: 'DELETE',
          credentials: 'include',
          headers: _webHeaders(mutating: true),
        ),
      ).toDart;
      return _webResponseToApi(response);
    }
    final response = await http.delete(
      Uri.parse(_buildUrl(path)),
      headers: _headers(mutating: true),
    );
    return ApiResponse.fromHttp(response);
  }

  web.Headers _webHeaders({bool mutating = false}) {
    final h = web.Headers();
    h.set('Accept', 'application/json');
    h.set('Content-Type', 'application/json');
    if (correlationId != null) {
      h.set('x-sentin8-correlation-id', correlationId!);
    }
    if (mutating && csrfToken != null) {
      h.set('X-BFF-CSRF', csrfToken!);
    }
    if (delegationId != null) {
      h.set('X-BFF-Delegation', delegationId!);
    }
    return h;
  }

  Future<ApiResponse> _webResponseToApi(web.Response response) async {
    final raw = (await response.text().toDart).toDart;
    final status = response.status;
    if (raw.isEmpty) {
      return ApiResponse(statusCode: status);
    }
    Object? body;
    try {
      body = jsonDecode(raw);
    } catch (_) {
      body = raw;
    }
    if (body is Map<String, dynamic>) {
      if (body.containsKey('success') && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ApiResponse(statusCode: status, data: data);
      }
      return ApiResponse(statusCode: status, data: body);
    }
    // Services return a bare JSON array (no envelope). Wrap it in
    // `{'data': body}` so callers can read it via `response.data!['data']`.
    if (body is List<dynamic>) {
      return ApiResponse(statusCode: status, data: {'data': body});
    }
    return ApiResponse(statusCode: status, error: raw);
  }
}

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

  factory ApiResponse.fromHttp(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (body is Map<String, dynamic>) {
      // Unwrap {success, data} envelope if present
      if (body.containsKey('success') && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ApiResponse(statusCode: response.statusCode, data: data);
      }
      return ApiResponse(statusCode: response.statusCode, data: body);
    }
    // Services return a bare JSON array (no envelope). Wrap it in
    // `{'data': body}` so callers can read it via `response.data!['data']`.
    if (body is List<dynamic>) {
      return ApiResponse(
        statusCode: response.statusCode,
        data: {'data': body},
      );
    }
    return ApiResponse(
      statusCode: response.statusCode,
      error: body is String ? body : response.body,
    );
  }
}