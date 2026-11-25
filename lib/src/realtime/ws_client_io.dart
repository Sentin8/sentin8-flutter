// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF WebSocket client - native transport (Android / iOS / desktop).
//
// Uses `dart:io`'s WebSocket. Unlike the browser transport this CAN set
// request headers on the upgrade, so the caller's opaque BFF session token
// rides `Authorization: Bearer …` directly - no cookie jar needed.
//
// Reached only through `ws_client.dart`'s conditional export.

import 'dart:io';

import 'ws_client_core.dart';

class BffWebSocket extends BffWebSocketBase {
  WebSocket? _socket;

  BffWebSocket({required super.bffBaseUrl, super.sessionToken});

  @override
  void openSocket(String url) {
    final headers = <String, dynamic>{
      if (sessionToken != null && sessionToken!.isNotEmpty)
        'Authorization': 'Bearer $sessionToken',
    };
    WebSocket.connect(url, headers: headers).then((socket) {
      _socket = socket;
      markOpen();
      socket.listen(
        (data) {
          if (data is String) {
            handleMessageText(data);
          } else if (data is List<int>) {
            handleMessageText(String.fromCharCodes(data));
          }
        },
        onDone: markClosed,
        onError: (_) => markFailed(),
        cancelOnError: true,
      );
    }).catchError((Object _) {
      markFailed();
    });
  }

  @override
  void sendRaw(String text) {
    _socket?.add(text);
  }

  @override
  void closeSocket() {
    // Close without awaiting: `disconnect()` is synchronous by contract.
    _socket?.close();
    _socket = null;
  }
}
