// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// WS3 regression gate: importing the barrel must compile on the Flutter VM
// (Android/iOS target). A package:web / dart:js_interop import anywhere in the
// barrel's transitive closure fails this test on the VM.
import 'package:flutter_test/flutter_test.dart';
import 'package:sentin8/sentin8.dart';

void main() {
  test('SDK barrel compiles for the VM (non-web)', () {
    expect(const BootstrapException('probe', 'detail').message, 'probe');
  });
}
