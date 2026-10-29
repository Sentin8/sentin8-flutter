// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// Runtime context resolution from TLS-injected headers.
//
// The app calls GET /v1/app/runtime/context. TLS reads the sentin8_tls_mappings
// table, identifies the app instance from the hostname, and injects
// X-Sentin8-App-Id, X-Sentin8-Env-Id headers. App uses these
// to return the full runtime context. No API key is needed.

import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

/// Runtime context resolved from App via TLS-injected headers.
///
/// This is the pre-login bootstrap context. It contains the Auth domain,
/// JWKS URI, organization, environment, and branding references that the
/// app needs to initialize before any user signs in.
class AppRuntimeContext {
  final String organizationId;
  final String environmentId;
  final String appSlug;
  final String hostname;
  final String authDomain;
  final String authIssuerJwksUri;
  final String bffDomain;
  final String status;
  final String instanceName;
  final String instanceDescription;
  final String organizationName;
  final String logoUrl;
  final String logoIconUrl;
  final String primaryColor;
  final String accentColor;
  final String fontFamily;
  final String themeMode;
  final Map<String, bool> featureFlags;
  final String instanceAuthDomain;
  final bool allowSignup;
  /// The app instance UUID (`application_id` from the runtime context)  - 
  /// used to derive the ID-based instance group name (§6.0c).
  final String applicationId;

  const AppRuntimeContext({
    required this.organizationId,
    required this.environmentId,
    required this.appSlug,
    required this.hostname,
    required this.authDomain,
    required this.authIssuerJwksUri,
    required this.bffDomain,
    required this.status,
    required this.instanceName,
    required this.instanceDescription,
    required this.organizationName,
    required this.logoUrl,
    required this.logoIconUrl,
    required this.primaryColor,
    required this.accentColor,
    required this.fontFamily,
    required this.themeMode,
    required this.featureFlags,
    this.instanceAuthDomain = '',
    this.allowSignup = true,
    this.applicationId = '',
  });

  /// Display name: instance name if set, otherwise org name, otherwise app slug.
  String get displayName =>
      instanceName.isNotEmpty ? instanceName
          : organizationName.isNotEmpty ? organizationName
          : appSlug;

  /// Auth issuer URL (e.g. https://sentin8-auth.prod.acme.local.sentin8.dev)
  String get authIssuer => 'https://$authDomain';

  /// BFF base URL for this app instance
  /// e.g. https://bff.bank8-ebank.prod.acme.local.sentin8.dev
  String get bffBaseUrl => 'https://$bffDomain';

  /// The Auth group name for this app instance.
  /// Users must be a member of this group to access the app.
  /// ID-based naming (architecture-principles §6.0c): the group is
  /// provisioned by the platform app service under the instance UUID →
  /// `sentin8:app:{application_id}` (the display-name-derived snake_case
  /// form is retired - its three implementations had drifted, AUTH-3).
  String get instanceGroupName => 'sentin8:app:$applicationId';

  /// Whether this app allows public sign-up (customer mode).
  /// When false, sign-up is hidden and only SSO is available (staff mode).
  bool get isStaffMode => !allowSignup;

  factory AppRuntimeContext.fromJson(Map<String, dynamic> json) {
    // Unwrap envelope if present (App returns {success, data} or {context})
    Map<String, dynamic> data = json;
    if (json.containsKey('success') && json['success'] == true) {
      data = json['data'] as Map<String, dynamic>? ?? json;
    } else if (json.containsKey('context')) {
      data = json['context'] as Map<String, dynamic>;
    } else if (json.containsKey('data')) {
      data = json['data'] as Map<String, dynamic>;
    }

    // Auth domain precedence (Story 12.4.2):
    // 1. `auth_domain` - the per-instance auth selected at install time
    //    (e.g. `auth.staff.{org}` for staff apps whose users live in the
    //    org-scoped staff env). This is where the app's users authenticate.
    // 2. `sentin8_auth_domain` - the env's own auth (e.g. `auth.{env}.{org}`),
    //    correct for customer apps installed in the same env as their users.
    // Staff apps are installed in the prod env but their users exist in the
    // staff env, so the env auth would 401 every staff sign-in.
    final authDomain = (data['auth_domain'] as String?)?.isNotEmpty == true
        ? data['auth_domain'] as String
        : data['sentin8_auth_domain'] as String? ?? '';
    final hostname = data['hostname'] as String? ?? '';
    final appSlug = data['app_slug'] as String? ?? 'app';

    final bffDomain = data['sentin8_bff_domain'] as String? ?? data['bff_domain'] as String? ?? data['bff_hostname'] as String? ?? '';

    final authIssuerJwksUri = 'https://$authDomain/.well-known/jwks.json';

    // Parse feature flags
    final flagsRaw = data['feature_flags'];
    Map<String, bool> flags = {};
    if (flagsRaw is Map) {
      flagsRaw.forEach((k, v) {
        flags[k.toString()] = v == true;
      });
    }

    return AppRuntimeContext(
      organizationId: data['org_id'] as String? ?? '',
      environmentId: data['env_id'] as String? ?? '',
      appSlug: appSlug,
      hostname: hostname,
      authDomain: authDomain,
      authIssuerJwksUri: authIssuerJwksUri,
      bffDomain: bffDomain,
      status: data['status'] as String? ?? 'active',
      instanceName: data['instance_name'] as String? ?? '',
      instanceDescription: data['instance_description'] as String? ?? '',
      organizationName: data['organization_name'] as String? ?? '',
      logoUrl: data['logo_url'] as String? ?? '',
      logoIconUrl: data['logo_icon_url'] as String? ?? '',
      primaryColor: data['primary_color'] as String? ?? '',
      accentColor: data['accent_color'] as String? ?? '',
      fontFamily: data['font_family'] as String? ?? '',
      themeMode: data['theme_mode'] as String? ?? '',
      featureFlags: flags,
      instanceAuthDomain: data['auth_domain'] as String? ?? '',
      allowSignup: data['allow_signup'] as bool? ?? true,
      applicationId: data['application_id'] as String? ?? '',
    );
  }
}

/// Fetch runtime context from App /v1/app/runtime/context endpoint.
/// The request is routed through TLS which injects X-Sentin8-* headers
/// based on the hostname. No API key or hostname parameter is needed.
///
/// [appBaseUrl] defaults to https://sentin8-app.ops.sys.local.sentin8.dev.
/// [logPrefix] is used for debug logging (e.g. 'eBank', 'eTeller').
Future<AppRuntimeContext> fetchRuntimeContext({
  String? appBaseUrl,
  String logPrefix = 'App',
}) async {
  final base = appBaseUrl ?? 'https://sentin8-app.ops.sys.local.sentin8.dev';

  final url = Uri.parse('$base/v1/app/runtime/context');

  final hostname = _getCurrentHostname();
  print('[$logPrefix] fetchRuntimeContext: url=$url hostname=$hostname');
  final response = await http.get(url, headers: {
    'Accept': 'application/json',
    'X-Sentin8-Hostname': hostname,
  });

  print('[$logPrefix] fetchRuntimeContext: response status=${response.statusCode} body=${response.body.length} chars');
  if (response.statusCode != 200) {
    print('[$logPrefix] fetchRuntimeContext: FAILED status=${response.statusCode} body=${response.body}');
    throw BootstrapException(
      'Failed to resolve runtime context: HTTP ${response.statusCode}',
      response.body,
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  print('[$logPrefix] fetchRuntimeContext: json keys=${json.keys.toList()}');

  // Fail-closed: if status is not active, reject
  final ctx = AppRuntimeContext.fromJson(json);
  print('[$logPrefix] fetchRuntimeContext: authDomain=${ctx.authDomain} bffDomain=${ctx.bffDomain} orgId=${ctx.organizationId} envId=${ctx.environmentId} status=${ctx.status}');
  if (ctx.status != 'active') {
    throw BootstrapException(
      'Instance is not active: ${ctx.status}',
      jsonEncode(json),
    );
  }

  if (ctx.authDomain.isEmpty) {
    throw BootstrapException(
      'Runtime context missing authDomain',
      jsonEncode(json),
    );
  }

  return ctx;
}

/// Get the current hostname from the browser.
String _getCurrentHostname() {
  try {
    return web.window.location.hostname;
  } catch (_) {
    return 'localhost';
  }
}

class BootstrapException implements Exception {
  final String message;
  final String detail;

  const BootstrapException(this.message, this.detail);

  @override
  String toString() => 'BootstrapException: $message';
}