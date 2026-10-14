// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF WebSocket client.
//
// Connects to BFF /ws after sign-in. Subscribes to delegation events,
// live page updates, and notifications. Pushes updates to the app via
// callbacks. Falls back to polling if WS is unavailable.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

class BffWebSocket {
  final String bffBaseUrl;
  web.WebSocket? _socket;
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

  BffWebSocket({required this.bffBaseUrl});

  bool get isConnected => _connected;

  void connect() {
    if (_connected || _reconnecting) return;
    final wsUrl = bffBaseUrl.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://');
    final url = '$wsUrl/ws';
    try {
      _socket = web.WebSocket(url);
      _socket!.onOpen.listen((_) {
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
      });
      _socket!.onMessage.listen((event) {
        final data = event.data;
        if (data != null) {
          try {
            final str = (data as dynamic).toString();
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
          } catch (_) {}
        }
      });
      _socket!.onClose.listen((_) {
        _connected = false;
        onDisconnected?.call();
        _scheduleReconnect();
      });
      _socket!.onError.listen((_) {
        _connected = false;
        _scheduleReconnect();
      });
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnecting) return;
    _reconnecting = true;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts > 5 ? 30 : 1 << _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnecting = false;
      connect();
    });
  }

  void _send(Map<String, dynamic> msg) {
    if (_connected && _socket != null) {
      _socket!.send(jsonEncode(msg).toJS);
    }
  }

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
    _socket?.close();
    _socket = null;
    _connected = false;
  }
}