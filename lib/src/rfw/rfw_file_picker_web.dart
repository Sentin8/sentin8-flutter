// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// RFW file-picker - browser implementation.
//
// Uses a native `<input type="file">` element and `FileReader`, exactly as the
// pre-seam code did inline in `rfw_renderer.dart`.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Result of a completed file pick.
class PickedFile {
  const PickedFile(this.name, this.base64Content);

  final String name;
  final String base64Content;
}

/// Prompt the user for one file and return its content base64-encoded.
///
/// Completes with `null` when the user dismisses the dialog or selects nothing.
Future<PickedFile?> pickFileAsBase64() {
  final completer = Completer<PickedFile?>();
  final input = html.FileUploadInputElement()..accept = '*/*';
  input.click();

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        if (!completer.isCompleted) {
          completer.complete(PickedFile(file.name, base64Encode(result)));
        }
      } else if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
