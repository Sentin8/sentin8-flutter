// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// RFW file-picker - native (Android / iOS / desktop) implementation.
//
// There is no platform file-input element on the VM. RFW pages are a
// browser-admin surface today (Dash, Bank8:Admin, Hotel8:EPMS, Bill8:Admin -
// Bank8:eBank has zero RFW usage), so this seam exists to let the SDK compile
// for native, not to make RFW uploads work yet.
//
// The honest options when an app does need it:
//   1. depend on `file_picker` (a plugin) and implement this function with it;
//   2. render the picker via a platform channel;
//   3. hide RFW file fields on native.
//
// Until one of those lands, a native RFW file field reports the limitation at
// runtime rather than silently doing nothing.

/// Result of a completed file pick.
class PickedFile {
  const PickedFile(this.name, this.base64Content);

  final String name;
  final String base64Content;
}

/// Always completes with `null` on native: no file input exists.
///
/// A page that genuinely needs uploads on native must adopt a file-picker
/// plugin; this contract deliberately does not fake success.
Future<PickedFile?> pickFileAsBase64() async {
  assert(() {
    // ignore: avoid_print
    print('[sentin8] RFW file picker is not implemented on native - '
        'the field will stay empty. Adopt a file-picker plugin to enable it.');
    return true;
  }());
  return null;
}
