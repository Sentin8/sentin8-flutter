// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// Native widget registry (rfw README §4, dash DESIGN.md).
//
// `WidgetNative.widget_name` accepts any string, but a renderer can only show
// widgets it knows. This registry is the seam: built-in widgets are registered
// by the host at boot, and any app (or tenant-supplied plugin) may register
// more. An unknown name renders a declared placeholder instead of dropping the
// widget silently, so a missing registration is visible to the operator rather
// than an invisible hole in the page.

import 'package:flutter/material.dart';

/// Renders a native widget by name. Returns `null` when the name is unknown.
typedef NativeWidgetBuilder = Widget? Function(
  String widgetName,
  Map<String, dynamic> props,
  String? dataEndpoint,
);

/// A registry of native widgets keyed by name.
///
/// One instance is shared per host. Registration is last-writer-wins so an
/// app can override a built-in without forking it.
class NativeWidgetRegistry {
  NativeWidgetRegistry();

  final Map<String, Widget Function(Map<String, dynamic> props, String? dataEndpoint)>
      _builders = {};

  /// Register a widget under [name]. Overrides any previous registration.
  void register(
    String name,
    Widget Function(Map<String, dynamic> props, String? dataEndpoint) builder,
  ) {
    _builders[name] = builder;
  }

  /// Register several at once.
  void registerAll(
    Map<String, Widget Function(Map<String, dynamic> props, String? dataEndpoint)>
        builders,
  ) {
    _builders.addAll(builders);
  }

  /// The registered names, for diagnostics and an operator "widgets" page.
  Iterable<String> get names => _builders.keys;

  /// Whether [name] is registered.
  bool has(String name) => _builders.containsKey(name);

  /// Render a widget, or `null` when the name is unknown.
  Widget? render(
    String name,
    Map<String, dynamic> props,
    String? dataEndpoint,
  ) {
    final builder = _builders[name];
    return builder?.call(props, dataEndpoint);
  }

  /// Render a widget, falling back to a visible placeholder for an unknown
  /// name. Prefer this over [render] at the call site: a silent `null` hides a
  /// deployment mistake.
  Widget renderOrPlaceholder(
    String name,
    Map<String, dynamic> props,
    String? dataEndpoint,
  ) {
    final widget = render(name, props, dataEndpoint);
    return widget ?? UnknownNativeWidget(widgetName: name);
  }
}

/// A visible placeholder for an unregistered native widget.
class UnknownNativeWidget extends StatelessWidget {
  /// The widget name that was not registered.
  final String widgetName;

  const UnknownNativeWidget({super.key, required this.widgetName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Unknown native widget',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '"$widgetName" is not registered in this host. '
            'Register it with NativeWidgetRegistry.register().',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
