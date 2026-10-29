// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// RFW Parser - deserializes JSON RFW definitions into typed Dart objects.
//
// The JSON structure mirrors the Rust `sentin8-rfw` crate types (widget.rs,
// page.rs, response.rs).

import 'dart:convert';

/// A single node in the remote widget tree.
class RemoteWidget {
  final String type;
  final Map<String, dynamic> props;

  RemoteWidget({required this.type, required this.props});

  factory RemoteWidget.fromJson(Map<String, dynamic> json) {
    return RemoteWidget(
      type: json['type'] as String,
      props: Map<String, dynamic>.from(json)..remove('type'),
    );
  }

  static List<RemoteWidget> fromJsonList(dynamic json) {
    if (json is! List) return [];
    return json.map((e) => RemoteWidget.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// A complete admin UI page definition.
class AdminUiPage {
  final String title;
  final List<RemoteWidget> widgets;
  final List<AdminUiAction> actions;

  AdminUiPage({
    required this.title,
    required this.widgets,
    required this.actions,
  });

  factory AdminUiPage.fromJson(Map<String, dynamic> json) {
    return AdminUiPage(
      title: json['title'] as String? ?? '',
      widgets: RemoteWidget.fromJsonList(json['widgets']),
      actions: (json['actions'] as List?)
          ?.map((e) => AdminUiAction.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

/// An action button shown in the page header.
class AdminUiAction {
  final String label;
  final String actionType; // link | submit | dialog
  final String? route;
  final String? endpoint;
  final String? icon;

  AdminUiAction({
    required this.label,
    required this.actionType,
    this.route,
    this.endpoint,
    this.icon,
  });

  factory AdminUiAction.fromJson(Map<String, dynamic> json) {
    return AdminUiAction(
      label: json['label'] as String? ?? '',
      actionType: json['action_type'] as String? ?? 'link',
      route: json['route'] as String?,
      endpoint: json['endpoint'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

/// The response envelope from an admin UI endpoint.
class AdminUiResponse {
  final String responseType; // page | redirect | error
  final AdminUiPage? page;
  final String? redirectRoute;
  final String? errorMessage;
  final List<FieldError> fieldErrors;

  AdminUiResponse({
    required this.responseType,
    this.page,
    this.redirectRoute,
    this.errorMessage,
    this.fieldErrors = const [],
  });

  factory AdminUiResponse.fromJson(Map<String, dynamic> json) {
    final responseType = json['response_type'] as String? ?? 'error';
    return AdminUiResponse(
      responseType: responseType,
      page: responseType == 'page' && json['page'] != null
          ? AdminUiPage.fromJson(json['page'] as Map<String, dynamic>)
          : null,
      redirectRoute: responseType == 'redirect' ? json['route'] as String? : null,
      errorMessage: responseType == 'error' ? json['message'] as String? : null,
      fieldErrors: (json['field_errors'] as List?)
          ?.map((e) => FieldError.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  factory AdminUiResponse.parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return AdminUiResponse.fromJson(json);
  }

  /// Create an error response.
  factory AdminUiResponse.error(String message) {
    return AdminUiResponse(
      responseType: 'error',
      errorMessage: message,
    );
  }
}

class FieldError {
  final String field;
  final String message;

  FieldError({required this.field, required this.message});

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// A vertical service entry discovered from Sentin8:Sys.
class VerticalService {
  final String service;
  final String label;
  final String icon;
  final String serviceFlag;
  bool enabled;
  final List<VerticalServicePage> pages;

  VerticalService({
    required this.service,
    required this.label,
    required this.icon,
    required this.serviceFlag,
    required this.enabled,
    required this.pages,
  });

  factory VerticalService.fromJson(Map<String, dynamic> json) {
    return VerticalService(
      service: json['service'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'extension',
      serviceFlag: json['service_flag'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      pages: (json['pages'] as List?)
          ?.map((e) => VerticalServicePage.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  static List<VerticalService> fromJsonList(dynamic json) {
    if (json is! List) return [];
    return json.map((e) => VerticalService.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class VerticalServicePage {
  final String route;
  final String label;
  final String uiEndpoint;
  final String dataEndpoint;
  final String icon;

  VerticalServicePage({
    required this.route,
    required this.label,
    required this.uiEndpoint,
    required this.dataEndpoint,
    required this.icon,
  });

  factory VerticalServicePage.fromJson(Map<String, dynamic> json) {
    return VerticalServicePage(
      route: json['route'] as String? ?? '',
      label: json['label'] as String? ?? '',
      uiEndpoint: json['ui_endpoint'] as String? ?? '',
      dataEndpoint: json['data_endpoint'] as String? ?? '',
      icon: json['icon'] as String? ?? 'circle',
    );
  }
}