// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// Runtime-context hostname source - platform selection.
//
// The `X-Sentin8-Hostname` header is how App resolves which instance a
// bootstrap call belongs to, so its value must never be guessed.
//
//   * web    - derive it from `window.location` (the page's own origin).
//   * native - there is no location bar. The caller supplies the enrolled
//              instance host explicitly; passing nothing is a hard error.
//
// The pre-split code returned the literal `'localhost'` when the browser lookup
// threw, which on a native target meant every bootstrap silently claimed to be
// the localhost instance - a fail-open default. `resolveHostname` removes it.

export 'hostname_source_io.dart'
    if (dart.library.js_interop) 'hostname_source_web.dart';
