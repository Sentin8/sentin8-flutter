// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF SSE notification client - platform selection.
//
// The shared lifecycle (unread accounting, reconnect policy, polling fallback)
// lives in `sse_client_core.dart`; only the stream transport differs.
//
// `dart.library.js_interop` selects the browser `EventSource`; everything else
// gets a raw `dart:io` HTTP stream with a hand-written SSE parser, which - unlike
// `EventSource` - can carry an `Authorization` header.

export 'sse_client_io.dart'
    if (dart.library.js_interop) 'sse_client_web.dart';
