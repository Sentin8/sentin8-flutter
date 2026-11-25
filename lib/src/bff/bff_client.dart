// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF proxy access layer - platform selection.
//
// All backend communication goes through BFF proxy routes. The client holds a
// session cookie (browser) or an opaque session token (native), never an OAuth
// token - the BFF attaches the real access token server-side.
//
// The wire contract (URL composition, headers, envelope unwrapping) lives in
// `bff_client_core.dart`; only the HTTP transport differs:
//
//   * `dart.library.js_interop` -> `window.fetch` with `credentials: 'include'`
//   * everything else           -> `dart:io` HttpClient with `Authorization`
//
// `ApiResponse` is re-exported so existing callers keep working unchanged.

export 'bff_client_io.dart'
    if (dart.library.js_interop) 'bff_client_web.dart';
export 'bff_client_core.dart' show ApiResponse;
