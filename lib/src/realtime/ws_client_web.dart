// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF WebSocket client - browser transport.
//
// Authenticates via the BFF session cookie (the browser sends it on the
// upgrade automatically) and uses the platform WebSocket. Reached only through
// `ws_client.dart`'s conditional export.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

import 'ws_client_core.dart';

class BffWebSocket extends BffWebSocketBase {
  web.WebSocket? _socket;

  BffWebSocket({required super.bffBaseUrl, super.sessionToken});

  @override
  void openSocket(String url) {
    final socket = web.WebSocket(url);
    _socket = socket;
    socket.onOpen.listen((_) => markOpen());
    socket.onMessage.listen((event) {
      final data = event.data;
      if (data != null) {
        handleMessageText(data.toString());
      }
    });
    socket.onClose.listen((_) => markClosed());
    socket.onError.listen((_) => markFailed());
  }

  @override
  void sendRaw(String text) {
    _socket?.send(text.toJS);
  }

  @override
  void closeSocket() {
    _socket?.close();
    _socket = null;
  }
}
