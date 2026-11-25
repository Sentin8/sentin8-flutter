// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF WebSocket client - platform selection.
//
// The shared lifecycle (callbacks, reconnect policy, event router) lives in
// `ws_client_core.dart`; only the transport differs per platform.
//
// `dart.library.js_interop` selects the browser transport; everything else
// (Android, iOS, desktop) gets the `dart:io` transport, which can send the
// opaque session token as an `Authorization` header on the upgrade.

export 'ws_client_io.dart'
    if (dart.library.js_interop) 'ws_client_web.dart';
