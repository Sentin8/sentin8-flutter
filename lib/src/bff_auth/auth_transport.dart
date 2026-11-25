// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// BFF auth transport - platform selection.
//
// The auth *state machine* (loaded / signed-in / user / scopes / csrf) is
// identical on every platform and lives in `auth_provider.dart`. Only two
// transport facts differ:
//
//   * how a session is read   (`fetchSessionJson`)
//   * how a sign-out is sent  (`postSignOut`)
//
// The browser uses `window.fetch` with `credentials: 'include'` so the HttpOnly
// `bff-session` cookie rides along. Native has no cookie jar, so it sends the
// opaque session token as `Authorization: Bearer`.
//
// Returning the raw JSON string from [fetchSessionJson] keeps envelope handling
// in one place and lets the caller keep its existing parsing.

export 'auth_transport_io.dart'
    if (dart.library.js_interop) 'auth_transport_web.dart';
