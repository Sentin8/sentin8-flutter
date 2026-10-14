// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// RFW Cache — LRU cache of fetched RFW definitions.
//
// Keyed by `{service}/{page}`. Invalidated on navigation or explicit refresh.

import 'rfw_parser.dart';

class RfwCache {
  final _cache = <String, AdminUiPage>{};
  final int maxSize;

  RfwCache({this.maxSize = 50});

  AdminUiPage? get(String service, String page) {
    final key = '$service/$page';
    return _cache[key];
  }

  void put(String service, String page, AdminUiPage def) {
    final key = '$service/$page';
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = def;
  }

  void invalidate(String service, String page) {
    _cache.remove('$service/$page');
  }

  void invalidateAll() {
    _cache.clear();
  }
}