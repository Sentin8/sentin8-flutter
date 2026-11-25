// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// URL hash router utility - platform selection.
//
// The web implementation drives `window.history`; the IO implementation is a
// deliberate no-op, because a native app has no address bar and no hash.
// Native navigation state belongs to the widget layer (Navigator /
// go_router), not to a global URL helper.
//
// `dart.library.js_interop` is the correct predicate: `dart.library.html` no
// longer distinguishes modern web from wasm, and `kIsWeb` is a runtime check
// that cannot rescue a compile-time import.

export 'url_router_io.dart'
    if (dart.library.js_interop) 'url_router_web.dart';
