// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF cookie-based session management - generic auth provider.
//
// Pattern:
// - BFF holds all OAuth tokens server-side (token guardian)
// - Flutter app only holds an opaque session cookie (__Host-bff-session)
// - signInWithAuth() redirects to BFF /auth/login → Auth /oauth/authorize
// - signOut() calls BFF /auth/sign-out
// - fetchSession() calls BFF /auth/session to check if signed in

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Auth state for the app.
class AuthState {
  final bool isLoaded;
  final bool isSignedIn;
  final AppUser? user;
  final String? accessToken;
  final List<String> scopes;
  final String? csrfToken;

  const AuthState({
    this.isLoaded = false,
    this.isSignedIn = false,
    this.user,
    this.accessToken,
    this.scopes = const [],
    this.csrfToken,
  });

  AuthState copyWith({
    bool? isLoaded,
    bool? isSignedIn,
    AppUser? user,
    String? accessToken,
    List<String>? scopes,
    String? csrfToken,
  }) {
    return AuthState(
      isLoaded: isLoaded ?? this.isLoaded,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      scopes: scopes ?? this.scopes,
      csrfToken: csrfToken ?? this.csrfToken,
    );
  }
}

/// User information from the BFF session.
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final List<String> groups;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.groups = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['display_name'] as String? ?? json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['picture'] as String?,
      groups: (json['groups'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  /// Check if the user is a member of the given group.
  bool isMemberOf(String groupName) => groups.contains(groupName);
}

/// Auth provider manages BFF session state.
///
/// Uses ChangeNotifier for reactive updates. On web, the __Host-bff-session
/// cookie is HttpOnly so we cannot read it directly - we must call BFF
/// /auth/session to check if the user is signed in.
///
/// [logPrefix] is used for debug logging (e.g. 'eBank', 'eTeller').
class BffAuthProvider extends ChangeNotifier {
  final String bffBaseUrl;
  final String authDomain;
  final String logPrefix;

  AuthState _state = const AuthState();

  BffAuthProvider({
    required this.bffBaseUrl,
    required this.authDomain,
    this.logPrefix = 'App',
  });

  AuthState get state => _state;
  bool get isLoaded => _state.isLoaded;
  bool get isSignedIn => _state.isSignedIn;
  AppUser? get user => _state.user;
  String? get csrfToken => _state.csrfToken;
  List<String> get scopes => _state.scopes;

  /// Initialize: check if the user has an active BFF session.
  Future<void> init() async {
    try {
      final session = await fetchSession();
      if (session != null) {
        _state = AuthState(
          isLoaded: true,
          isSignedIn: true,
          user: session.user,
          scopes: session.scopes,
          csrfToken: session.csrfToken,
        );
      } else {
        _state = const AuthState(isLoaded: true);
      }
    } catch (e) {
      _state = const AuthState(isLoaded: true);
    }
    notifyListeners();
  }

  /// Fetch session from BFF. Returns null if not signed in.
  Future<_SessionData?> fetchSession() async {
    print('[$logPrefix] fetchSession: calling $bffBaseUrl/auth/session');
    if (kIsWeb) {
      final response = await web.window.fetch(
        '$bffBaseUrl/auth/session'.toJS,
        web.RequestInit(
          method: 'GET',
          credentials: 'include',
        ),
      ).toDart;
      print('[$logPrefix] fetchSession: response status=${response.status}');
      if (response.status != 200) {
        return null;
      }
      final raw = (await response.text().toDart).toDart;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final userJson = json['user'] as Map<String, dynamic>?;
      if (userJson == null) return null;

      final scopes = _parseScopes(json['scopes'] ?? json['scope']);

      return _SessionData(
        user: AppUser.fromJson(userJson),
        scopes: scopes,
        csrfToken: json['csrf_token'] as String? ?? json['csrfToken'] as String?,
      );
    }
    // Non-web (mobile): use the standard http client.
    final url = Uri.parse('$bffBaseUrl/auth/session');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final userJson = json['user'] as Map<String, dynamic>?;
      if (userJson == null) return null;

      final scopes = _parseScopes(json['scopes'] ?? json['scope']);

      return _SessionData(
        user: AppUser.fromJson(userJson),
        scopes: scopes,
        csrfToken: json['csrf_token'] as String? ?? json['csrfToken'] as String?,
      );
    }
    return null;
  }

  /// Redirect to BFF login → Auth OAuth authorize flow.
  void signInWithAuth() {
    print('[$logPrefix] signInWithAuth: redirecting to $bffBaseUrl/auth/login');
    _redirect('$bffBaseUrl/auth/login');
  }

  /// Redirect to BFF sign-up → Auth sign-up page with full OAuth params.
  void signUpWithAuth() {
    print('[$logPrefix] signUpWithAuth: redirecting to $bffBaseUrl/auth/sign-up');
    _redirect('$bffBaseUrl/auth/sign-up');
  }

  /// Sign out: terminate BFF session.
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        final h = web.Headers();
        h.set('Accept', 'application/json');
        h.set('Content-Type', 'application/json');
        if (_state.csrfToken != null) {
          h.set('X-BFF-CSRF', _state.csrfToken!);
        }
        await web.window.fetch(
          '$bffBaseUrl/auth/sign-out'.toJS,
          web.RequestInit(
            method: 'POST',
            credentials: 'include',
            headers: h,
            body: '{}'.toJS,
          ),
        ).toDart;
      } else {
        final url = Uri.parse('$bffBaseUrl/auth/sign-out');
        await http.post(url, headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_state.csrfToken != null) 'X-BFF-CSRF': _state.csrfToken!,
        });
      }
    } catch (_) {
      // Best effort - clear local state regardless
    }
    _state = const AuthState(isLoaded: true);
    notifyListeners();
  }

  void _redirect(String url) {
    onRedirect?.call(url);
  }

  /// Callback for handling redirects (set by the UI layer).
  void Function(String url)? onRedirect;
}

class _SessionData {
  final AppUser user;
  final List<String> scopes;
  final String? csrfToken;

  const _SessionData({
    required this.user,
    required this.scopes,
    this.csrfToken,
  });
}

/// Parse the `scopes` field from the BFF session response. The BFF returns
/// scopes as a JSON array, but older responses may return a space-separated
/// string. This helper handles both formats.
List<String> _parseScopes(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  if (raw is String) {
    return raw.split(' ').where((s) => s.isNotEmpty).toList();
  }
  return [];
}