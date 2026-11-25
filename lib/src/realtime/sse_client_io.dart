// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF SSE notification client - native transport (Android / iOS / desktop).
//
// There is no `EventSource` outside the browser, so this opens a raw HTTP
// request and parses the SSE wire format itself:
//
//   event: sentin8:notification.received
//   data: {"unread_count":3,...}
//   <blank line>
//
// A raw request is strictly more capable than `EventSource` here: it can send
// `Authorization: Bearer <token>`, which the browser API cannot.
//
// Reached only through `sse_client.dart`'s conditional export.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'sse_client_core.dart';

class NotificationSseClient extends NotificationSseClientBase {
  HttpClient? _http;
  StreamSubscription<String>? _sub;

  NotificationSseClient({
    required super.bffBaseUrl,
    super.fetchUnreadCount,
    super.sessionToken,
  });

  @override
  void openStream(String url) {
    final uri = Uri.parse(url);
    final client = HttpClient();
    _http = client;

    client
        .getUrl(uri)
        .then((request) {
          request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
          request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
          if (sessionToken != null && sessionToken!.isNotEmpty) {
            request.headers
                .set(HttpHeaders.authorizationHeader, 'Bearer $sessionToken');
          }
          return request.close();
        })
        .then((response) {
          if (response.statusCode != HttpStatus.ok) {
            debugPrint('SSE: HTTP ${response.statusCode} - falling back to polling');
            response.drain<void>().catchError((Object _) {});
            markClosed();
            return;
          }
          // 200 + event-stream: the stream is live.
          markOpen();
          final parser = _SseParser((event, data) => handleEventData(event, data));
          _sub = response
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(
                parser.feed,
                onDone: markClosed,
                onError: (Object _) => markClosed(),
                cancelOnError: true,
              );
        })
        .catchError((Object e) {
          debugPrint('SSE connect failed: $e');
          markClosed();
        });
  }

  @override
  void closeStream() {
    _sub?.cancel();
    _sub = null;
    _http?.close(force: true);
    _http = null;
  }
}

/// Minimal SSE wire-format parser.
///
/// Handles multi-line `data:` accumulation (joined with `\n` per the SSE
/// specification), comment lines (`:` heartbeats), and the default event name
/// `message`. Deliberately ignores `id:`/`retry:` - the BFF sends neither, and
/// reconnect timing is owned by [NotificationSseClientBase.scheduleReconnect].
class _SseParser {
  _SseParser(this.onEvent);

  final void Function(String eventName, String data) onEvent;

  static const _defaultEvent = 'message';

  String _event = _defaultEvent;
  final List<String> _data = [];

  void feed(String line) {
    if (line.isEmpty) {
      _dispatch();
      return;
    }
    if (line.startsWith(':')) {
      // Comment / heartbeat - keep the connection, emit nothing.
      return;
    }
    final colon = line.indexOf(':');
    final field = colon == -1 ? line : line.substring(0, colon);
    var value = colon == -1 ? '' : line.substring(colon + 1);
    // A single leading space after the colon is stripped (SSE §9.2.6).
    if (value.startsWith(' ')) value = value.substring(1);

    if (field == 'event') {
      _event = value;
    } else if (field == 'data') {
      _data.add(value);
    }
    // Other fields (id, retry) are intentionally ignored.
  }

  void _dispatch() {
    if (_data.isEmpty) {
      _event = _defaultEvent;
      return;
    }
    final payload = _data.join('\n');
    final name = _event;
    _event = _defaultEvent;
    _data.clear();
    onEvent(name, payload);
  }
}
