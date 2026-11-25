// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// RFW file-picker seam - platform selection.
//
// RFW pages are the remote-admin-UI surface. They are consumed today only by
// browser admin apps (Dash, Bank8:Admin, Hotel8:EPMS, Bill8:Admin), where a
// native `<input type="file">` works. The VM has no such element, so the IO
// implementation reports the limitation explicitly instead of failing to
// compile - which is what `dart:html` did before this seam existed.
//
// `dart.library.js_interop` selects the browser implementation.

export 'rfw_file_picker_io.dart'
    if (dart.library.js_interop) 'rfw_file_picker_web.dart';
