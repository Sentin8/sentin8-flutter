// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF SSE notification client - browser transport.
//
// Uses the platform `EventSource`; `withCredentials: true` carries the BFF
// session cookie. Reached only through `sse_client.dart`'s conditional export.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

import 'sse_client_core.dart';

class NotificationSseClient extends NotificationSseClientBase {
  web.EventSource? _eventSource;

  NotificationSseClient({
    required super.bffBaseUrl,
    super.fetchUnreadCount,
    super.sessionToken,
  });

  @override
  void openStream(String url) {
    final source = web.EventSource(
      url,
      web.EventSourceInit(withCredentials: true),
    );
    _eventSource = source;
    source.onOpen.listen((_) => markOpen());
    source.addEventListener(
      'sentin8:notification.received',
      ((web.MessageEvent e) {
        final data = e.data;
        if (data != null) {
          handleEventData('sentin8:notification.received', data.toString());
        }
      }).toJS,
    );
    source.addEventListener(
      'sentin8:notification.read',
      ((web.MessageEvent e) {
        final data = e.data;
        if (data != null) {
          handleEventData('sentin8:notification.read', data.toString());
        }
      }).toJS,
    );
    source.onError.listen((_) => markClosed());
  }

  @override
  void closeStream() {
    _eventSource?.close();
    _eventSource = null;
  }
}
