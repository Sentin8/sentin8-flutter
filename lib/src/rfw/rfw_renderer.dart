// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// RFW Renderer — inflates RemoteWidget definitions into native Flutter widgets.
//
// Supports: Container, Text, DataTable, Form, Button, Card, Chart, Native,
// Row, Column, Spacer.

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rfw_parser.dart';

/// Renders a list of RemoteWidget definitions into a Flutter widget tree.
class RfwRenderer extends StatelessWidget {
  final List<RemoteWidget> widgets;
  final RfwActions actions;
  final Map<String, dynamic>? extraProps;

  const RfwRenderer({
    super.key,
    required this.widgets,
    required this.actions,
    this.extraProps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets.map((w) => _renderWidget(context, w)).toList(),
    );
  }

  Widget _renderWidget(BuildContext context, RemoteWidget widget) {
    switch (widget.type) {
      case 'Container':
        return _renderContainer(context, widget);
      case 'Text':
        return _renderText(context, widget);
      case 'DataTable':
        return _renderDataTable(context, widget);
      case 'Form':
        return _renderForm(context, widget);
      case 'Button':
        return _renderButton(context, widget);
      case 'Card':
        return _renderCard(context, widget);
      case 'Chart':
        return _renderChart(context, widget);
      case 'Native':
        return _renderNative(context, widget);
      case 'Row':
        return _renderRow(context, widget);
      case 'Column':
        return _renderColumn(context, widget);
      case 'Spacer':
        return SizedBox(
            height: (widget.props['size'] as num?)?.toDouble() ?? 16);
      default:
        return Text('Unknown widget type: ${widget.type}',
            style: const TextStyle(color: Colors.red));
    }
  }

  Widget _renderContainer(BuildContext context, RemoteWidget w) {
    final children = (w.props['children'] as List?)
            ?.map((e) => RemoteWidget.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final direction = w.props['direction'] as String? ?? 'vertical';
    final spacing = (w.props['spacing'] as num?)?.toDouble() ?? 0;
    final padding = (w.props['padding'] as num?)?.toDouble() ?? 0;

    final childWidgets =
        children.map((c) => _renderWidget(context, c)).toList();

    if (direction == 'horizontal') {
      return Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children:
              childWidgets.expand((c) => [c, SizedBox(width: spacing)]).toList()
                ..removeLast(),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            childWidgets.expand((c) => [c, SizedBox(height: spacing)]).toList()
              ..removeLast(),
      ),
    );
  }

  Widget _renderText(BuildContext context, RemoteWidget w) {
    final text = w.props['text'] as String? ?? '';
    final textType = w.props['text_type'] as String? ?? 'body';
    final align = w.props['align'] as String? ?? 'left';

    final style = switch (textType) {
      'heading' => Theme.of(context).textTheme.headlineSmall,
      'subheading' => Theme.of(context).textTheme.titleMedium,
      'title' => Theme.of(context).textTheme.titleLarge,
      'caption' => Theme.of(context).textTheme.bodySmall,
      'label' => Theme.of(context).textTheme.labelMedium,
      _ => Theme.of(context).textTheme.bodyMedium,
    };

    final textAlign = switch (align) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

    return Text(text, style: style, textAlign: textAlign);
  }

  Widget _renderDataTable(BuildContext context, RemoteWidget w) {
    final columnsRaw = w.props['columns'] as List? ?? [];
    final columns = columnsRaw
        .map((c) => DataTableColumn.fromJson(c as Map<String, dynamic>))
        .toList();
    final dataEndpoint = w.props['data_endpoint'] as String? ?? '';
    final emptyMessage = w.props['empty_message'] as String?;
    final rowActionsRaw = w.props['row_actions'] as List? ?? [];
    final rowActions = rowActionsRaw
        .map((a) => RowAction.fromJson(a as Map<String, dynamic>))
        .toList();
    final hasRowActions = rowActions.isNotEmpty;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: actions.fetchData(dataEndpoint),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(emptyMessage ?? 'No data available.',
                style: Theme.of(context).textTheme.bodySmall),
          );
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(emptyMessage ?? 'No data.',
                style: Theme.of(context).textTheme.bodySmall),
          );
        }

        // Build row action buttons for a given row.
        List<Widget> buildActionButtons(Map<String, dynamic> row) {
          if (!hasRowActions) return [];
          return rowActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: action.route != null
                  ? TextButton(
                      onPressed: () {
                        final route = action.route!
                            .replaceAll('{id}', row['id']?.toString() ?? '');
                        actions.onNavigate(route);
                      },
                      child: Text(action.label),
                    )
                  : action.endpoint != null
                      ? FilledButton(
                          onPressed: () async {
                            try {
                              final result = await actions.submitForm(
                                  action.endpoint!.replaceAll(
                                      '{id}', row['id']?.toString() ?? ''),
                                  {});
                              // Handle redirect response — navigate to the
                              // returned route (e.g. after install, redirect
                              // to the instance page).
                              if (result.responseType == 'redirect' &&
                                  result.redirectRoute != null) {
                                actions.onNavigate(result.redirectRoute!);
                              }
                            } catch (_) {
                              // Silently ignore — the error is already logged
                              // by the ApiClient.
                            }
                          },
                          child: Text(action.label),
                        )
                      : Text(action.label),
            );
          }).toList();
        }

        // Card-based layout for all screen sizes — flexible, scrollable,
        // and mobile-friendly. Each row becomes a card with label:value
        // fields and action buttons at the bottom.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows.map((row) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show each field as a label: value row.
                      ...columns.map((c) {
                        final value = _formatValue(row[c.key], c.format);
                        if (value.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c.label}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Expanded(
                                  child: Text(value,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        );
                      }),
                      // Action buttons row — right-aligned.
                      if (hasRowActions)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ...buildActionButtons(row),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _renderForm(BuildContext context, RemoteWidget w) {
    final fieldsRaw = w.props['fields'] as List? ?? [];
    final fields = fieldsRaw
        .map((f) => FormFieldDef.fromJson(f as Map<String, dynamic>))
        .toList();
    final submitEndpoint = w.props['submit_endpoint'] as String? ?? '';
    final submitLabel = w.props['submit_label'] as String? ?? 'Submit';
    final cancelLabel = w.props['cancel_label'] as String? ?? 'Cancel';

    return RfwForm(
      fields: fields,
      submitEndpoint: submitEndpoint,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
      actions: actions,
      extraProps: extraProps,
    );
  }

  Widget _renderButton(BuildContext context, RemoteWidget w) {
    final label = w.props['label'] as String? ?? '';
    final buttonType = w.props['button_type'] as String? ?? 'primary';
    final route = w.props['route'] as String?;
    final iconCode = w.props['icon'] as String?;

    // Build the button child — support multi-line labels (split on \n)
    // and optional leading icons (Material Icons hex code points).
    final labelLines = label.split('\n');
    final hasIcon = iconCode != null && iconCode.isNotEmpty;
    final icon = hasIcon
        ? Icon(IconData(int.parse(iconCode, radix: 16), fontFamily: 'MaterialIcons'),
            size: 20)
        : null;

    Widget buildChild() {
      if (labelLines.length <= 1 && !hasIcon) {
        return Text(label);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: labelLines
                  .map((line) => Text(
                        line,
                        style: labelLines.indexOf(line) == 0
                            ? Theme.of(context).textTheme.titleSmall
                            : Theme.of(context).textTheme.bodySmall,
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    }

    final style = switch (buttonType) {
      'secondary' => ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary),
      'danger' => ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError),
      'ghost' => TextButton.styleFrom(),
      'link' => TextButton.styleFrom(),
      _ => ElevatedButton.styleFrom(),
    };

    if (buttonType == 'link' || buttonType == 'ghost') {
      return TextButton(
        onPressed: route != null ? () => actions.onNavigate(route) : null,
        child: buildChild(),
      );
    }
    return ElevatedButton(
      style: style,
      onPressed: route != null ? () => actions.onNavigate(route) : null,
      child: buildChild(),
    );
  }

  Widget _renderCard(BuildContext context, RemoteWidget w) {
    final title = w.props['title'] as String?;
    final subtitle = w.props['subtitle'] as String?;
    final children = (w.props['children'] as List?)
            ?.map((e) => RemoteWidget.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final actions = (w.props['actions'] as List?)
            ?.map((e) => RemoteWidget.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
            ],
            ...children.map((c) => _renderWidget(context, c)),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((a) => _renderWidget(context, a)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _renderChart(BuildContext context, RemoteWidget w) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (w.props['title'] != null)
              Text(w.props['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
                'Chart: ${w.props['chart_type'] ?? 'bar'} (data: ${w.props['data_endpoint']})',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _renderNative(BuildContext context, RemoteWidget w) {
    final widgetName = w.props['widget_name'] as String? ?? '';
    final dataEndpoint = w.props['data_endpoint'] as String?;

    // Native widget host registry — the dash ships with built-in widgets
    // for complex interactive pages that RFW can't handle.
    return (actions.renderNativeWidget
            ?.call(widgetName, w.props, dataEndpoint)) ??
        Text('Native widget not found: $widgetName',
            style: const TextStyle(color: Colors.orange));
  }

  Widget _renderRow(BuildContext context, RemoteWidget w) {
    final children = (w.props['children'] as List?)
            ?.map((e) => RemoteWidget.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final spacing = (w.props['spacing'] as num?)?.toDouble() ?? 8;
    return Row(
      children: children
          .map((c) => Expanded(child: _renderWidget(context, c)))
          .expand((c) => [c, SizedBox(width: spacing)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _renderColumn(BuildContext context, RemoteWidget w) {
    final children = (w.props['children'] as List?)
            ?.map((e) => RemoteWidget.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final spacing = (w.props['spacing'] as num?)?.toDouble() ?? 8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children
          .expand((c) => [_renderWidget(context, c), SizedBox(height: spacing)])
          .toList()
        ..removeLast(),
    );
  }

  String _formatValue(dynamic value, String? format) {
    if (value == null) return '';
    if (format == 'currency') {
      final num v =
          (value is num) ? value : double.tryParse(value.toString()) ?? 0;
      return v.toStringAsFixed(2);
    }
    if (format == 'datetime') {
      return value.toString();
    }
    return value.toString();
  }
}

/// Actions available to the RFW renderer (data fetching, navigation, form submission).
class RfwActions {
  final Future<List<Map<String, dynamic>>> Function(String dataEndpoint)
      fetchData;
  final void Function(String route) onNavigate;
  final void Function(String rowId) onRowClick;
  final Future<AdminUiResponse> Function(
      String endpoint, Map<String, dynamic> body) submitForm;
  final Widget? Function(
          String widgetName, Map<String, dynamic> props, String? dataEndpoint)?
      renderNativeWidget;
  /// Raw admin GET (path relative to `/v1/admin/`, same normalization as
  /// [fetchData]) returning the decoded JSON envelope as-is. Native widgets
  /// that need non-list envelopes (e.g. the policy editor's single-set
  /// fetch) use this instead of [fetchData], which expects row arrays.
  final Future<Map<String, dynamic>> Function(String endpoint)? rawGet;
  /// Raw admin POST for native widgets that submit their own payload shape
  /// (e.g. the policy simulator's dry-run + save). Returns the decoded JSON.
  final Future<Map<String, dynamic>> Function(String endpoint,
      Map<String, dynamic> body)? rawPost;

  RfwActions({
    required this.fetchData,
    required this.onNavigate,
    required this.onRowClick,
    required this.submitForm,
    this.renderNativeWidget,
    this.rawGet,
    this.rawPost,
  });
}

// ── Helper classes ──

class DataTableColumn {
  final String key;
  final String label;
  final bool sortable;
  final String? format;

  DataTableColumn(
      {required this.key,
      required this.label,
      this.sortable = false,
      this.format});

  factory DataTableColumn.fromJson(Map<String, dynamic> json) {
    return DataTableColumn(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      sortable: json['sortable'] as bool? ?? false,
      format: json['format'] as String?,
    );
  }
}

/// A per-row action button in a DataTable.
class RowAction {
  final String label;
  final String? route;
  final String? endpoint;

  RowAction({required this.label, this.route, this.endpoint});

  factory RowAction.fromJson(Map<String, dynamic> json) {
    return RowAction(
      label: json['label'] as String? ?? '',
      route: json['route'] as String?,
      endpoint: json['endpoint'] as String?,
    );
  }
}

class FormFieldDef {
  final String key;
  final String label;
  final String fieldType;
  final bool required;
  final String? placeholder;
  final List<FormFieldOption> options;
  final FieldCondition? visibleIf;
  final dynamic defaultValue;
  final String? helpText;

  FormFieldDef({
    required this.key,
    required this.label,
    required this.fieldType,
    required this.required,
    this.placeholder,
    this.options = const [],
    this.visibleIf,
    this.defaultValue,
    this.helpText,
  });

  factory FormFieldDef.fromJson(Map<String, dynamic> json) {
    return FormFieldDef(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      fieldType: json['field_type'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      options: (json['options'] as List?)
              ?.map((e) => FormFieldOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      visibleIf: json['visible_if'] != null
          ? FieldCondition.fromJson(json['visible_if'] as Map<String, dynamic>)
          : null,
      defaultValue: json['default_value'],
      helpText: json['help_text'] as String?,
    );
  }
}

class FieldCondition {
  final String field;
  final String equals;

  FieldCondition({required this.field, required this.equals});

  factory FieldCondition.fromJson(Map<String, dynamic> json) {
    return FieldCondition(
      field: json['field'] as String? ?? '',
      equals: json['equals'] as String? ?? '',
    );
  }
}

class FormFieldOption {
  final String value;
  final String label;
  FormFieldOption({required this.value, required this.label});

  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

// ── Form widget ──

class RfwForm extends StatefulWidget {
  final List<FormFieldDef> fields;
  final String submitEndpoint;
  final String submitLabel;
  final String cancelLabel;
  final RfwActions actions;
  final Map<String, dynamic>? extraProps;

  const RfwForm({
    super.key,
    required this.fields,
    required this.submitEndpoint,
    required this.submitLabel,
    required this.cancelLabel,
    required this.actions,
    this.extraProps,
  });

  @override
  State<RfwForm> createState() => _RfwFormState();
}

class _RfwFormState extends State<RfwForm> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, dynamic>{};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill _values from each field's default_value.
    // This is critical for hidden fields (e.g. bucket name) and
    // fields with presets (e.g. status=active).
    for (final f in widget.fields) {
      if (f.defaultValue != null) {
        _values[f.key] = f.defaultValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill values from extraProps (e.g. listing_id from URL).
    if (widget.extraProps != null) {
      widget.extraProps!.forEach((key, value) {
        _values[key] = value;
      });
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.fields.map((f) {
            // Check conditional visibility.
            if (f.visibleIf != null) {
              final currentVal = _values[f.visibleIf!.field];
              if (currentVal?.toString() != f.visibleIf!.equals) {
                return const SizedBox.shrink();
              }
            }
            return _buildField(f);
          }),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.cancelLabel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(FormFieldDef f) {
    // Hidden fields don't render a widget — their value comes from
    // extraProps (e.g. listing_id pre-filled from the URL).
    if (f.fieldType == 'hidden') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: switch (f.fieldType) {
        'select' => DropdownButtonFormField<String>(
            decoration: InputDecoration(
                labelText: f.label, border: const OutlineInputBorder()),
            value: _values[f.key]?.toString(),
            items: f.options
                .map((o) =>
                    DropdownMenuItem(value: o.value, child: Text(o.label)))
                .toList(),
            onChanged: (v) {
              _values[f.key] = v;
              setState(() {}); // Rebuild to show/hide conditional fields.
            },
          ),
        'multiselect' => _MultiSelectField(
            label: f.label,
            options: f.options,
            initialSelection: (_values[f.key] as List<dynamic>?)?.cast<String>() ?? const [],
            onChanged: (selected) {
              _values[f.key] = selected;
            },
          ),
        'autocomplete' => _AutocompleteField(
            label: f.label,
            options: f.options,
            placeholder: f.placeholder,
            initialSelection: (_values[f.key] as List<dynamic>?)?.cast<String>() ?? const [],
            onChanged: (selected) {
              _values[f.key] = selected;
            },
          ),
        'key_value' => _KeyValueField(
            label: f.label,
            helpText: f.helpText,
            onChanged: (map) {
              _values[f.key] = map;
            },
          ),
        'checkbox' => CheckboxFormField(
            label: f.label,
            initialValue: _values[f.key] == true || _values[f.key] == 'true',
            onChanged: (v) {
              _values[f.key] = v;
              setState(() {});
            },
          ),
        'toggle' => SwitchFormField(
            label: f.label,
            initialValue: _values[f.key] == true || _values[f.key] == 'true',
            onChanged: (v) {
              _values[f.key] = v;
              setState(() {});
            },
          ),
        'textarea' => TextFormField(
            decoration: InputDecoration(
                labelText: f.label, border: const OutlineInputBorder()),
            maxLines: 4,
            initialValue: _values[f.key]?.toString(),
            onSaved: (v) => _values[f.key] = v ?? '',
          ),
        'file' => _FilePickerField(
            label: f.label,
            onChanged: (fileName, base64Content) {
              _values['file_name'] = fileName;
              _values['content_base64'] = base64Content;
            },
          ),
        _ => TextFormField(
            decoration: InputDecoration(
              labelText: f.label,
              hintText: f.placeholder,
              border: const OutlineInputBorder(),
            ),
            initialValue: _values[f.key]?.toString(),
            obscureText: f.fieldType == 'password',
            keyboardType: switch (f.fieldType) {
              'number' => TextInputType.number,
              'decimal' => const TextInputType.numberWithOptions(decimal: true),
              'percentage' => const TextInputType.numberWithOptions(decimal: true),
              'email' => TextInputType.emailAddress,
              _ => TextInputType.text,
            },
            inputFormatters: switch (f.fieldType) {
              'number' => [
                  ThousandsInputFormatter(integerOnly: true),
                ],
              'decimal' => [
                  ThousandsInputFormatter(integerOnly: false),
                ],
              'percentage' => [
                  ThousandsInputFormatter(integerOnly: false),
                ],
              _ => null,
            },
            // Commit on every keystroke (not only at form.save) so the
            // form state always reflects what the user typed — a submit
            // that races ahead of form.save would send empty values.
            onChanged: (v) {
              _values[f.key] = v ?? '';
            },
            // Strip thousand separators (commas) from the stored value
            // so the backend receives a clean numeric string.
            onSaved: (v) {
              if (f.fieldType == 'number' ||
                  f.fieldType == 'decimal' ||
                  f.fieldType == 'percentage') {
                _values[f.key] = v?.replaceAll(',', '') ?? '';
              } else {
                _values[f.key] = v ?? '';
              }
            },
          ),
      },
    );
  }

  Future<void> _submit() async {
    _formKey.currentState?.save();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final response =
          await widget.actions.submitForm(widget.submitEndpoint, _values);
      if (response.responseType == 'redirect' &&
          response.redirectRoute != null) {
        widget.actions.onNavigate(response.redirectRoute!);
      } else if (response.responseType == 'error') {
        setState(() => _error = response.errorMessage);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }
}

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField(
      {required String label, required ValueChanged<bool> onChanged, bool initialValue = false, super.key})
      : super(
          initialValue: initialValue,
          builder: (state) {
            return CheckboxListTile(
              title: Text(label),
              value: state.value ?? false,
              onChanged: (v) {
                state.didChange(v);
                onChanged(v ?? false);
              },
            );
          },
        );
}

/// Toggle switch form field — used for boolean parameters.
class SwitchFormField extends FormField<bool> {
  SwitchFormField(
      {required String label, required ValueChanged<bool> onChanged, bool initialValue = false, super.key})
      : super(
          initialValue: initialValue,
          builder: (state) {
            return SwitchListTile(
              title: Text(label),
              value: state.value ?? false,
              onChanged: (v) {
                state.didChange(v);
                onChanged(v);
              },
            );
          },
        );
}

/// Multi-select field with checkboxes inside a dropdown panel.
/// Used for assigning multiple scopes, users, or roles.
class _MultiSelectField extends StatefulWidget {
  final String label;
  final List<FormFieldOption> options;
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;

  const _MultiSelectField({
    required this.label,
    required this.options,
    required this.initialSelection,
    required this.onChanged,
  });

  @override
  State<_MultiSelectField> createState() => _MultiSelectFieldState();
}

class _MultiSelectFieldState extends State<_MultiSelectField> {
  late List<String> _selected;
  bool _expanded = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelection);
  }

  List<FormFieldOption> get _filteredOptions {
    if (_searchQuery.isEmpty) return widget.options;
    final q = _searchQuery.toLowerCase();
    return widget.options
        .where((o) => o.label.toLowerCase().contains(q) || o.value.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              suffixIcon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            ),
            child: _selected.isEmpty
                ? Text('None selected', style: Theme.of(context).textTheme.bodyMedium)
                : Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: _selected.map((value) {
                      final opt = widget.options.firstWhere(
                        (o) => o.value == value,
                        orElse: () => FormFieldOption(value: value, label: value),
                      );
                      return Chip(
                        label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _selected.remove(value));
                          widget.onChanged(_selected);
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 4),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search ${widget.label.toLowerCase()}...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: _filteredOptions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No matches found',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: _filteredOptions.map((opt) {
                      final isSelected = _selected.contains(opt.value);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(opt.label),
                        subtitle: opt.value != opt.label ? Text(opt.value, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(opt.value);
                            } else {
                              _selected.remove(opt.value);
                            }
                          });
                          widget.onChanged(_selected);
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }
}

/// Autocomplete multi-select field — a text input that filters options as
/// the user types, with chips showing selected items. Clicking a suggestion
/// adds it to the selection. Chips can be tapped to remove.
class _AutocompleteField extends StatefulWidget {
  final String label;
  final List<FormFieldOption> options;
  final String? placeholder;
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;

  const _AutocompleteField({
    required this.label,
    required this.options,
    this.placeholder,
    required this.initialSelection,
    required this.onChanged,
  });

  @override
  State<_AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<_AutocompleteField> {
  late List<String> _selected;
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<FormFieldOption> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelection);
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _suggestions = widget.options
          .where((o) =>
              !_selected.contains(o.value) &&
              o.label.toLowerCase().contains(q))
          .take(10)
          .toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _add(FormFieldOption opt) {
    setState(() {
      _selected.add(opt.value);
      _controller.clear();
      _showSuggestions = false;
    });
    widget.onChanged(_selected);
  }

  void _remove(String value) {
    setState(() {
      _selected.remove(value);
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: Theme.of(context).textTheme.titleSmall),
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _selected.map((value) {
                final opt = widget.options.firstWhere(
                  (o) => o.value == value,
                  orElse: () => FormFieldOption(value: value, label: value),
                );
                return Chip(
                  label: Text(opt.label),
                  onDeleted: () => _remove(value),
                );
              }).toList(),
            ),
          ),
        TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: InputDecoration(
            hintText: widget.placeholder ?? 'Search…',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: _filter,
          onTap: () {
            if (_controller.text.isNotEmpty) _filter(_controller.text);
          },
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              children: _suggestions.map((opt) {
                return ListTile(
                  dense: true,
                  title: Text(opt.label),
                  onTap: () => _add(opt),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Key-value field — renders a dynamic list of parameter name/value pairs.
/// The user can add/remove rows. The result is a Map<String, String> passed
/// to onChanged, suitable for JSON parameters blobs.
class _KeyValueField extends StatefulWidget {
  final String label;
  final String? helpText;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _KeyValueField({
    required this.label,
    this.helpText,
    required this.onChanged,
  });

  @override
  State<_KeyValueField> createState() => _KeyValueFieldState();
}

class _KeyValueFieldState extends State<_KeyValueField> {
  final List<_KVRow> _rows = [];

  void _notify() {
    final map = <String, dynamic>{};
    for (final r in _rows) {
      if (r.key.trim().isNotEmpty) {
        // Try to parse as number/bool, fall back to string.
        final v = r.value.trim();
        if (v == 'true') {
          map[r.key.trim()] = true;
        } else if (v == 'false') {
          map[r.key.trim()] = false;
        } else if (double.tryParse(v) != null) {
          map[r.key.trim()] = double.parse(v);
        } else {
          map[r.key.trim()] = v;
        }
      }
    }
    widget.onChanged(map);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.helpText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(widget.helpText!, style: Theme.of(context).textTheme.bodySmall),
          ),
        ..._rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Parameter',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      row.key = v;
                      _notify();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) {
                      row.value = v;
                      _notify();
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    setState(() => _rows.removeAt(i));
                    _notify();
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() => _rows.add(_KVRow()));
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add Parameter', style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _KVRow {
  String key = '';
  String value = '';
}

/// File picker field — uses the HTML file input to select a file.
/// Reads the file as base64 and passes (fileName, base64Content) to onChanged.
class _FilePickerField extends StatefulWidget {
  final String label;
  final void Function(String fileName, String base64Content) onChanged;

  const _FilePickerField({
    required this.label,
    required this.onChanged,
  });

  @override
  State<_FilePickerField> createState() => _FilePickerFieldState();
}

class _FilePickerFieldState extends State<_FilePickerField> {
  String? _fileName;
  bool _loading = false;

  Future<void> _pickFile() async {
    final input = html.FileUploadInputElement()..accept = '*/*';
    input.click();

    input.onChange.listen((_) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      setState(() => _loading = true);
      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is Uint8List) {
          final base64Content = base64Encode(result);
          setState(() {
            _fileName = file.name;
            _loading = false;
          });
          widget.onChanged(file.name, base64Content);
        }
      });

      reader.readAsArrayBuffer(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_loading ? 'Reading...' : 'Choose File'),
            ),
            const SizedBox(width: 12),
            if (_fileName != null)
              Expanded(
                child: Text(
                  _fileName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Text('No file selected',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

/// TextInputFormatter that adds thousand separators (commas) to numbers.
///
/// For `integerOnly: true` — only digits are allowed, grouped as 1,234,567.
/// For `integerOnly: false` — digits and one decimal point are allowed,
/// formatted as 1,234,567.89.
///
/// The raw numeric value (without commas) is what the form submits —
/// the formatter stores the display value (with commas) in the field
/// and the raw value can be recovered by stripping commas.
class ThousandsInputFormatter extends TextInputFormatter {
  final bool integerOnly;

  ThousandsInputFormatter({this.integerOnly = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits and one decimal point.
    String text = newValue.text;
    // Remove any existing commas first.
    text = text.replaceAll(',', '');

    if (integerOnly) {
      // Keep only digits.
      text = text.replaceAll(RegExp(r'[^\d]'), '');
    } else {
      // Keep only digits and one decimal point.
      final hasDecimal = text.contains('.');
      text = text.replaceAll(RegExp(r'[^\d.]'), '');
      if (hasDecimal) {
        // Keep only the first decimal point.
        final parts = text.split('.');
        if (parts.length > 2) {
          text = '${parts[0]}.${parts.sublist(1).join()}';
        }
      }
    }

    // Split into integer and decimal parts.
    String integerPart;
    String decimalPart = '';
    if (text.contains('.')) {
      final parts = text.split('.');
      integerPart = parts[0];
      decimalPart = parts.length > 1 ? '.${parts[1]}' : '.';
    } else {
      integerPart = text;
    }

    // Add thousand separators to the integer part.
    final formatted = <String>[];
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted.insert(0, ',');
      }
      formatted.insert(0, integerPart[i]);
      count++;
    }

    final formattedInteger = formatted.join();
    final result = formattedInteger + decimalPart;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

// ── Native `policy_simulator` host (policy design §3.7, story 28.14) ──────
//
// The RFW page definition (served by the adopting service) declares a
// `Native` widget with `widget_name: "policy_simulator"`. The dash's
// native-widget registry maps that name to this stateful host, which the
// page configures via `props`:
//   save_endpoint  — admin-relative POST alias carrying the set name
//                    (e.g. `/v1/admin/policy-sets/{name}/save`)
//   test_endpoint  — admin-relative dry-run alias (e.g. `…/{name}/test`)
//   default_action — pre-filled sample action id
//   service        — colon service_type (label only)
// and fetches the current set via `data_endpoint`.
//
// Trust boundary: the simulation is a SERVER-side dry-run through
// `actions.rawPost` — the browser never evaluates policy (§3.3: Shield is
// the single in-process decision point; live identity resolution only
// exists server-side). This host is form + display logic only.
class PolicySimulatorWidget extends StatefulWidget {
  final Map<String, dynamic> props;
  final String? dataEndpoint;
  final RfwActions actions;

  const PolicySimulatorWidget({
    super.key,
    required this.props,
    this.dataEndpoint,
    required this.actions,
  });

  @override
  State<PolicySimulatorWidget> createState() => _PolicySimulatorWidgetState();
}

class _PolicySimulatorWidgetState extends State<PolicySimulatorWidget> {
  // Editor state.
  final _policiesCtrl = TextEditingController();
  final _schemaCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  // Simulator state.
  final _subjectCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  final _scopesCtrl = TextEditingController();
  String _tokenTp = 'user';
  bool _loading = true;
  bool _running = false;
  bool _saving = false;
  String? _error;
  String? _origin;
  String? _mode;
  // The set name is read from props OR from the fetched row ({name} may be
  // literal in the page definition when the dash renders it without a row
  // context); resolved into one getter.
  String _fetchedName = '';
  // Dry-run result.
  bool? _allowed;
  String? _reason;
  String? _simError;

  String get _saveEndpoint =>
      widget.props['save_endpoint'] as String? ?? '';
  String get _testEndpoint =>
      widget.props['test_endpoint'] as String? ?? '';
  String get _setName {
    // The page definition embeds the CONCRETE set name per-set (the page is
    // generated by the service for `policy-sets/{name}/edit`) — no renderer
    // substitution is needed here (§3.7). Falls back to the fetched row for
    // hosts that render the page without per-set props.
    final fromProps = (widget.props['policy_set_name'] as String? ?? '').trim();
    if (fromProps.isNotEmpty && fromProps != '{name}') return fromProps;
    return _fetchedName;
  }

  @override
  void initState() {
    super.initState();
    _actionCtrl.text =
        widget.props['default_action'] as String? ?? '';
    _load();
  }

  @override
  void dispose() {
    _policiesCtrl.dispose();
    _schemaCtrl.dispose();
    _descriptionCtrl.dispose();
    _subjectCtrl.dispose();
    _actionCtrl.dispose();
    _scopesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.dataEndpoint == null || widget.actions.rawGet == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final raw = await widget.actions.rawGet!(widget.dataEndpoint!);
      final set = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;
      if (!mounted) return;
      setState(() {
        _fetchedName = set['policy_set_name']?.toString() ?? '';
        _policiesCtrl.text = set['policies']?.toString() ?? '';
        _schemaCtrl.text = set['schema']?.toString() ?? '';
        _descriptionCtrl.text = set['description']?.toString() ?? '';
        _origin = set['origin']?.toString();
        _mode = set['mode']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _runSimulation() async {
    if (widget.actions.rawPost == null) return;
    setState(() {
      _running = true;
      _simError = null;
      _allowed = null;
      _reason = null;
    });
    try {
      final res = await widget.actions.rawPost!(_testEndpoint, {
        'policies': _policiesCtrl.text,
        if (_schemaCtrl.text.trim().isNotEmpty) 'schema': _schemaCtrl.text,
        'subject_id': _subjectCtrl.text.trim().isEmpty
            ? 'sample-subject'
            : _subjectCtrl.text.trim(),
        'token_tp': _tokenTp,
        'scopes': _scopesCtrl.text
            .split(RegExp(r'[\s,]+'))
            .where((s) => s.isNotEmpty)
            .toList(),
        if (_actionCtrl.text.trim().isNotEmpty) 'action': _actionCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        final decision = res['decision'];
        // decision serializes as {decision: allow} | {decision: deny, reason}.
        _allowed = decision is Map && decision['decision'] == 'allow';
        _reason = decision is Map && decision['reason'] != null
            ? decision['reason'].toString()
            : null;
        _running = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _simError = e.toString();
          _running = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (widget.actions.rawPost == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await widget.actions.rawPost!(_saveEndpoint, {
        'policies': _policiesCtrl.text,
        'description': _descriptionCtrl.text,
        if (_schemaCtrl.text.trim().isNotEmpty) 'schema': _schemaCtrl.text,
        'mode': _mode ?? 'shadow',
        'enabled': true,
      });
      if (!mounted) return;
      if (res['response_type'] == 'error') {
        setState(() {
          _error = res['message']?.toString() ?? 'Save failed';
          _saving = false;
        });
        return;
      }
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policy set saved (hot-reloaded via bus event)')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (_error != null && _policiesCtrl.text.isEmpty) {
      return Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error));
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editor card.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      _setName.isEmpty ? 'Shield Policy' : 'Shield Policy: $_setName',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (_origin != null) Text('origin: $_origin', style: theme.textTheme.bodySmall),
                  if (_mode != null) ...[
                    const SizedBox(width: 12),
                    Text('mode: $_mode', style: theme.textTheme.bodySmall),
                  ],
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _policiesCtrl,
                  maxLines: 12,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Shield Policies',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    helperText: 'One statement per permit/forbid; validated at write time (fail-closed §3.1).',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _schemaCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Shield Schema (optional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Simulator card — server-side dry-run, never client-side eval.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Simulation Playground', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Evaluates your candidate text on the service (dry-run endpoint) — the decision engine stays in-process per §3.3.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sample subject id', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _actionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Action id', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _scopesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sample scopes (space-separated)',
                    border: OutlineInputBorder(),
                    helperText: 'Simulates the live effective scope set (§3.1d).',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _tokenTp,
                  decoration: const InputDecoration(
                      labelText: 'Token type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('user')),
                    DropdownMenuItem(value: 'm2m', child: Text('m2m')),
                    DropdownMenuItem(value: 'delegated', child: Text('delegated')),
                  ],
                  onChanged: (v) => setState(() => _tokenTp = v ?? 'user'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _running ? null : _runSimulation,
                    icon: _running
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Run'),
                  ),
                ),
                if (_simError != null) ...[
                  const SizedBox(height: 8),
                  Text(_simError!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                if (_allowed != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _allowed!
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(_allowed! ? Icons.check_circle : Icons.block,
                              size: 20,
                              color: _allowed!
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            _allowed! ? 'ALLOW' : 'DENY',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                        if (_reason != null) ...[
                          const SizedBox(height: 4),
                          Text(_reason!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
