// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicmagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF SSE notification client - shared core.
//
// Connects to BFF `GET /subscribe?types=sentin8:notification.received,sentin8:notification.read`
// and keeps an unread-count badge in sync. The stream is one-way, so SSE with
// exponential reconnect is simpler than a WebSocket.
//
// Platform transports differ (`EventSource` on the browser, a raw HTTP stream
// on Android/iOS), so `_web` / `_io` own the connection. Everything else -
// unread accounting, the reconnect policy, and the polling fallback - lives
// here.
//
// IMPORTANT: the previous implementation began `connect()` with
// `if (!kIsWeb) return;`, which also skipped `startPolling()` - so on native
// neither SSE **nor** the polling fallback ever ran and the badge silently
// never updated. [connect] here starts polling unconditionally on every
// platform; SSE is an enhancement layered on top of polling, never a
// replacement for it.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

typedef FetchUnreadCount = Future<int> Function();

/// Transport contract implemented by `sse_client_web.dart` / `sse_client_io.dart`.
abstract class NotificationSseClientBase extends ChangeNotifier {
  final String bffBaseUrl;
  final FetchUnreadCount? fetchUnreadCount;

  /// Opaque BFF session credential.
  ///
  /// The browser transport authenticates with cookies (EventSource's
  /// `withCredentials`), so it ignores this. The IO transport has no cookie
  /// jar and sends `Authorization: Bearer <token>`.
  final String? sessionToken;

  bool _connected = false;
  int _unreadCount = 0;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  NotificationSseClientBase({
    required this.bffBaseUrl,
    this.fetchUnreadCount,
    this.sessionToken,
  });

  int get unreadCount => _unreadCount;
  bool get isConnected => _connected;

  String get streamUrl =>
      '$bffBaseUrl/subscribe?types=sentin8:notification.received,sentin8:notification.read';

  // ── Transport hooks ────────────────────────────────────────────────────

  /// Open the stream. The implementation dispatches each `sentin8:notification.*`
  /// event's data string to [handleEventData] and calls [markClosed] on error.
  void openStream(String url);

  /// Tear down the transport without scheduling a reconnect.
  void closeStream();

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Connect to the stream and start the polling safety net.
  ///
  /// Polling starts on EVERY platform (the pre-split bug skipped it off-web).
  void connect() {
    if (_connected || _reconnectTimer != null) return;
    _refreshUnreadCount();
    startPolling();
    try {
      openStream(streamUrl);
    } catch (e) {
      debugPrint('SSE connect failed: $e');
      scheduleReconnect();
    }
  }

  /// Called by the transport when the stream opens.
  void markOpen() {
    _connected = true;
    _reconnectAttempts = 0;
    _refreshUnreadCount();
    notifyListeners();
  }

  /// Called by the transport when the stream errors or ends.
  void markClosed() {
    _connected = false;
    notifyListeners();
    scheduleReconnect();
  }

  /// Feed one SSE `data:` payload, tagged with its event name.
  void handleEventData(String eventName, String data) {
    try {
      final msg = jsonDecode(data) as Map<String, dynamic>;
      switch (eventName) {
        case 'sentin8:notification.received':
          if (msg['unread_count'] is num) {
            _unreadCount = (msg['unread_count'] as num).toInt();
          } else {
            _unreadCount++;
          }
          notifyListeners();
          debugPrint(
              '[SSE] sentin8:notification.received: ${msg['title']} (unread=$_unreadCount)');
          break;
        case 'sentin8:notification.read':
          if (msg['unread_count'] is num) {
            _unreadCount = (msg['unread_count'] as num).toInt();
            notifyListeners();
            debugPrint('[SSE] sentin8:notification.read: unread=$_unreadCount');
          }
          break;
      }
    } catch (e) {
      debugPrint('SSE message parse error: $e');
    }
  }

  void scheduleReconnect() {
    if (_reconnectTimer != null) return;
    _reconnectAttempts++;
    final delay =
        Duration(seconds: _reconnectAttempts > 5 ? 30 : 1 << _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      closeStream();
      connect();
    });
  }

  // ── Unread count ───────────────────────────────────────────────────────

  Future<void> _refreshUnreadCount() async {
    if (fetchUnreadCount == null) return;
    try {
      final count = await fetchUnreadCount!();
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('[SSE] unread count fetch failed: $e');
    }
  }

  void markAllRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// Immediately decrement the unread count by 1 (optimistic update).
  void decrementUnread() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  /// Re-fetch the unread count from the API.
  Future<void> refreshUnreadCount() async {
    await _refreshUnreadCount();
  }

  Timer? _pollTimer;

  /// Start a background poll that refreshes the unread count every 5 seconds.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _refreshUnreadCount());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Teardown ───────────────────────────────────────────────────────────

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    stopPolling();
    closeStream();
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
