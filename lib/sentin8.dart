// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// sentin8 — Unified Flutter SDK for Sentin8 apps.
//
// This package provides the shared design system, BFF client, auth provider,
// routing, realtime (SSE + WebSocket), hooks, widgets, and observability
// used across all Sentin8 Flutter web apps (eBank, eTeller, eFintech, Dash).
//
// Usage:
//   import 'package:sentin8/sentin8.dart';

// === Theme ===
export 'src/theme/colors.dart';
export 'src/theme/spacing.dart';
export 'src/theme/text_styles.dart';
export 'src/theme/theme_builder.dart';
export 'src/theme/glass_panel.dart';
export 'src/theme/logo.dart';

// === Bootstrap ===
export 'src/bootstrap/runtime_context.dart';
export 'src/bootstrap/bootstrap_loader.dart';
export 'src/bootstrap/bootstrap_error.dart';

// === BFF Client ===
export 'src/bff/bff_client.dart';
export 'src/bff/correlation.dart';

// === BFF Auth ===
export 'src/bff_auth/auth_provider.dart';

// === Routing ===
export 'src/routing/url_router.dart';

// === Realtime ===
export 'src/realtime/sse_client.dart';
export 'src/realtime/ws_client.dart';

// === Hooks ===
export 'src/hooks/data_state.dart';

// === Utils ===
export 'src/utils/money.dart';
export 'src/utils/account_helpers.dart';

// === Shell Widgets ===
export 'src/shell/nav_item.dart';
export 'src/shell/user_menu.dart';
export 'src/shell/notification_bell.dart';
export 'src/shell/access_denied.dart';
export 'src/shell/landing_page.dart';

// === Observability ===
export 'src/observability/logger.dart';

// === RFW (Remote Flutter Widgets) ===
export 'src/rfw/rfw_parser.dart';
export 'src/rfw/rfw_renderer.dart';
export 'src/rfw/rfw_cache.dart';
export 'src/rfw/rfw_page.dart';