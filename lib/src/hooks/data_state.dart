// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

/// Base state for data-fetching hooks.
class DataState<T> {
  final T? data;
  final bool isLoading;
  final String? error;

  const DataState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  bool get hasData => data != null;
}