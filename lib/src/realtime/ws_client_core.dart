// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF WebSocket client - shared core.
//
// Connects to BFF /ws after sign-in. Subscribes to delegation events, live
// page updates, and notifications. Pushes updates to the app via callbacks.
// Falls back to reconnecting with exponential backoff when the socket drops.
//
// Platform transports differ (`package:web` WebSocket on the browser,
// `dart:io` WebSocket on Android/iOS/desktop), so the socket object lives in
// the `_web` / `_io` implementations. Everything else - the callback surface,
// the reconnect policy, and the vertical-agnostic event router - lives here so
// the two transports cannot drift.

import 'dart:async';
import 'dart:convert';

/// Transport contract implemented by `ws_client_web.dart` / `ws_client_io.dart`.
abstract class BffWebSocketBase {
  final String bffBaseUrl;

  /// Opaque BFF session credential.
  ///
  /// The browser transport authenticates with cookies, so it ignores this.
  /// The IO transport has no ambient cookie jar and sends it as
  /// `Authorization: Bearer <token>` on the upgrade request.
  final String? sessionToken;

  bool _connected = false;
  bool _reconnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  // Event callbacks
  void Function(Map<String, dynamic>)? onDelegationResult;
  void Function(Map<String, dynamic>)? onDelegationExpired;
  void Function(Map<String, dynamic>)? onNotification;
  void Function(Map<String, dynamic>)? onAccountUpdate;
  void Function(Map<String, dynamic>)? onPaymentStatusChanged;
  void Function(Map<String, dynamic>)? onConsentRevoked;
  void Function(Map<String, dynamic>)? onUserUpdated;
  void Function(Map<String, dynamic>)? onLogEntry;
  void Function(Map<String, dynamic>)? onAppInstanceStatus;
  void Function()? onConnected;
  void Function()? onDisconnected;

  BffWebSocketBase({required this.bffBaseUrl, this.sessionToken});

  bool get isConnected => _connected;

  /// `wss://…/ws` (or `ws://` for a plain-HTTP base URL).
  String get socketUrl {
    final wsUrl = bffBaseUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');
    return '$wsUrl/ws';
  }

  // ── Transport hooks (implemented per platform) ─────────────────────────

  /// Open a socket to [url]. The implementation must call [markOpen] on
  /// success, [handleMessageText] per frame, [markClosed] on close and
  /// [markFailed] on error.
  void openSocket(String url);

  /// Send one text frame.
  void sendRaw(String text);

  /// Close the socket without triggering the reconnect policy.
  void closeSocket();

  // ── Lifecycle ──────────────────────────────────────────────────────────

  void connect() {
    if (_connected || _reconnecting) return;
    try {
      openSocket(socketUrl);
    } catch (e) {
      markFailed();
    }
  }

  /// Called by the transport once the socket is open.
  void markOpen() {
    _connected = true;
    _reconnectAttempts = 0;
    _reconnecting = false;
    _send({
      'action': 'subscribe',
      'types': [
        'sentin8:delegation.result',
        'sentin8:delegation.expired',
        'sentin8:notification.received',
        'sentin8:app.instance.status',
        'sentin8:bff.session.expired',
      ],
    });
    onConnected?.call();
  }

  /// Called by the transport for each inbound frame.
  void handleMessageText(String str) {
    try {
      final msg = jsonDecode(str) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      switch (type) {
        case 'sentin8:delegation.result':
          onDelegationResult?.call(msg);
          break;
        case 'sentin8:delegation.expired':
          onDelegationExpired?.call(msg);
          break;
        case 'sentin8:notification.received':
          onNotification?.call(msg);
          break;
        default:
          // Route events by resource family, not by vertical prefix.
          // This matches any vertical's events (bank8:ledger.*,
          // hotel8:pos.*, etc.) without hardcoding vertical names.
          if (type != null) {
            if (type.contains(':ledger.account.')) {
              onAccountUpdate?.call(msg);
            } else if (type.contains(':payments.payment.') ||
                type.contains(':payments.instruction.')) {
              onPaymentStatusChanged?.call(msg);
            } else if (type.contains(':fdx.consent.')) {
              onConsentRevoked?.call(msg);
            } else if (type == 'sentin8:auth.user.updated') {
              onUserUpdated?.call(msg);
            } else if (type == 'sentin8:log.entry') {
              onLogEntry?.call(msg);
            } else if (type == 'sentin8:app.instance.status') {
              onAppInstanceStatus?.call(msg);
            }
          }
          break;
      }
    } catch (_) {
      // Malformed frame: ignore, never tear down the stream.
    }
  }

  /// Called by the transport when the peer closes the socket.
  void markClosed() {
    _connected = false;
    onDisconnected?.call();
    scheduleReconnect();
  }

  /// Called by the transport on a socket error.
  void markFailed() {
    _connected = false;
    scheduleReconnect();
  }

  void scheduleReconnect() {
    if (_reconnecting) return;
    _reconnecting = true;
    _reconnectAttempts++;
    final delay =
        Duration(seconds: _reconnectAttempts > 5 ? 30 : 1 << _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnecting = false;
      connect();
    });
  }

  void _send(Map<String, dynamic> msg) {
    if (_connected) {
      sendRaw(jsonEncode(msg));
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Subscribe to event types. Replaces the current subscription set.
  void subscribe(List<String> types) {
    _send({'action': 'subscribe', 'types': types});
  }

  /// Subscribe to page-scoped events with an optional resource_id filter.
  void subscribeToPage(List<String> types, {String? resourceId}) {
    final msg = <String, dynamic>{'action': 'subscribe', 'types': types};
    if (resourceId != null && resourceId.isNotEmpty) {
      msg['resource_id'] = resourceId;
    }
    _send(msg);
  }

  /// Unsubscribe from all events.
  void unsubscribe() {
    _send({'action': 'unsubscribe'});
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnecting = false;
    closeSocket();
    _connected = false;
  }
}
