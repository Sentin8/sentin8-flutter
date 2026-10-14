// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF SSE notification client.
//
// Connects to BFF GET /subscribe?types=sentin8:notification.received,sentin8:notification.read (SSE stream).
// On each event, updates the unread count and notifies listeners.
// The SSE stream is authenticated via the BFF session cookie
// (credentials: 'include' in EventSource polyfill).
//
// Design: design/sentin8-post-technical-design.md §13 Epic 18.6
// BFF SSE: design/sentin8-bff-technical-design.md §12.3

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

typedef FetchUnreadCount = Future<int> Function();

class NotificationSseClient extends ChangeNotifier {
  final String bffBaseUrl;
  final FetchUnreadCount? fetchUnreadCount;
  web.EventSource? _eventSource;
  bool _connected = false;
  int _unreadCount = 0;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  int get unreadCount => _unreadCount;
  bool get isConnected => _connected;

  NotificationSseClient({required this.bffBaseUrl, this.fetchUnreadCount});

  void connect() {
    if (!kIsWeb) return; // SSE is web-only
    if (_connected || _reconnectTimer != null) return;
    _refreshUnreadCount();
    startPolling();

    final url = '$bffBaseUrl/subscribe?types=sentin8:notification.received,sentin8:notification.read';
    try {
      _eventSource = web.EventSource(
        url,
        web.EventSourceInit(withCredentials: true),
      );
      _eventSource!.onOpen.listen((_) {
        _connected = true;
        _reconnectAttempts = 0;
        _refreshUnreadCount();
        notifyListeners();
      });
      _eventSource!.addEventListener('sentin8:notification.received', _onNotification.toJS);
      _eventSource!.addEventListener('sentin8:notification.read', _onNotificationRead.toJS);
      _eventSource!.onError.listen((_) {
        _connected = false;
        notifyListeners();
        _scheduleReconnect();
      });
    } catch (e) {
      debugPrint('SSE connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _onNotification(web.MessageEvent event) {
    try {
      final str = (event.data as dynamic).toString();
      final msg = jsonDecode(str) as Map<String, dynamic>;
      if (msg['unread_count'] is num) {
        _unreadCount = (msg['unread_count'] as num).toInt();
      } else {
        _unreadCount++;
      }
      notifyListeners();
      debugPrint('[SSE] sentin8:notification.received: ${msg['title']} (unread=$_unreadCount)');
    } catch (e) {
      debugPrint('SSE message parse error: $e');
    }
  }

  void _onNotificationRead(web.MessageEvent event) {
    try {
      final str = (event.data as dynamic).toString();
      final msg = jsonDecode(str) as Map<String, dynamic>;
      if (msg['unread_count'] is num) {
        _unreadCount = (msg['unread_count'] as num).toInt();
        notifyListeners();
        debugPrint('[SSE] sentin8:notification.read: unread=$_unreadCount');
      }
    } catch (e) {
      debugPrint('SSE sentin8:notification.read parse error: $e');
    }
  }

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
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshUnreadCount());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts > 5 ? 30 : 1 << _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _cleanupEventSource();
      connect();
    });
  }

  void _cleanupEventSource() {
    _eventSource?.close();
    _eventSource = null;
    _connected = false;
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    stopPolling();
    _cleanupEventSource();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}