// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

// Shared RFW page widget - fetches and renders remote admin UI pages.
//
// Used by both Sentin8:Dash and vertical admin apps (e.g. Bank8:Admin).
// The app provides a [BffApiClient] for the target service and a navigation
// callback. The widget handles fetching the RFW definition, rendering it via
// [RfwRenderer], and handling form submissions + navigation.
//
// Usage:
//   Sentin8RfwPage(
//     service: 'ledger',
//     page: 'products',
//     bffClient: services.ledger,
//     onNavigate: (route) => navigateTo('/ledger/$route'),
//   )

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../bff/bff_client.dart';
import 'rfw_parser.dart';
import 'rfw_renderer.dart';
import 'rfw_cache.dart';

/// A self-contained RFW page that fetches and renders a remote admin UI page.
///
/// The [bffClient] is the BFF proxy client for the target service (e.g.
/// `services.ledger`). The [onNavigate] callback is called when the RFW
/// renderer navigates to a new page within the same service.
class Sentin8RfwPage extends StatefulWidget {
  final String service;
  final String page;
  final BffApiClient bffClient;
  final void Function(String route) onNavigate;
  final Map<String, dynamic>? extraProps;

  const Sentin8RfwPage({
    super.key,
    required this.service,
    required this.page,
    required this.bffClient,
    required this.onNavigate,
    this.extraProps,
  });

  @override
  State<Sentin8RfwPage> createState() => _Sentin8RfwPageState();
}

class _Sentin8RfwPageState extends State<Sentin8RfwPage> {
  AdminUiPage? _pageDef;
  bool _loading = true;
  String? _error;
  final _cache = RfwCache();

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void didUpdateWidget(Sentin8RfwPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if service, page, or extraProps (e.g. ?type= param) changed.
    if (oldWidget.service != widget.service ||
        oldWidget.page != widget.page ||
        (oldWidget.extraProps?.toString() ?? '') !=
            (widget.extraProps?.toString() ?? '')) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Build the cache key - include the type param so different product
    // type forms don't collide in the cache.
    final cacheKey = widget.extraProps != null && widget.extraProps!['type'] != null
        ? '${widget.page}?type=${widget.extraProps!['type']}'
        : widget.page;

    // Try cache first - but skip cache for pages with extraProps (e.g.
    // ?type=current_account) since those have dynamic content (internal
    // account dropdowns populated from the DB).
    final skipCache = widget.extraProps != null && widget.extraProps!.isNotEmpty;
    if (!skipCache) {
      final cached = _cache.get(widget.service, cacheKey);
      if (cached != null) {
        setState(() {
          _pageDef = cached;
          _loading = false;
        });
        return;
      }
    }

    try {
      // Build the admin UI URL, appending query params from extraProps
      // (e.g. ?type=current_account for product creation forms).
      var adminUiPath = '/v1/admin/ui/${widget.page}';
      if (widget.extraProps != null && widget.extraProps!['type'] != null) {
        adminUiPath += '?type=${widget.extraProps!['type']}';
      }

      final response = await widget.bffClient.get(adminUiPath);
      if (response.data == null) {
        setState(() {
          _error = response.error ?? 'Empty response (status ${response.statusCode})';
          _loading = false;
        });
        return;
      }
      print('[Sentin8RfwPage] Response data keys: ${response.data!.keys.toList()}');
      final adminResponse = AdminUiResponse.fromJson(response.data!);
      print('[Sentin8RfwPage] Response type: ${adminResponse.responseType}');

      if (adminResponse.responseType == 'page' && adminResponse.page != null) {
        print('[Sentin8RfwPage] Page title: ${adminResponse.page!.title}, widgets: ${adminResponse.page!.widgets.length}, actions: ${adminResponse.page!.actions.length}');
        // Only cache static pages (no extraProps) - dynamic pages with
        // extraProps (e.g. product forms with internal account dropdowns)
        // must re-fetch every time to get fresh DB data.
        if (!skipCache) {
          _cache.put(widget.service, cacheKey, adminResponse.page!);
        }
        setState(() {
          _pageDef = adminResponse.page;
          _loading = false;
        });
      } else if (adminResponse.responseType == 'error') {
        setState(() {
          _error = adminResponse.errorMessage ?? 'Unknown error';
          _loading = false;
        });
      }
    } catch (e, stack) {
      print('[Sentin8RfwPage] Error loading page: $e');
      print('[Sentin8RfwPage] Stack: $stack');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }
    if (_pageDef == null) {
      return const Center(child: Text('No page definition'));
    }

    final page = _pageDef!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page title + action buttons.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(page.title, style: Theme.of(context).textTheme.headlineMedium ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              // Render page-level actions (e.g. "Create Product").
              Row(
                children: page.actions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilledButton.icon(
                      onPressed: () {
                        if (action.route != null) {
                          widget.onNavigate(action.route!);
                        }
                      },
                      icon: Icon(action.icon == 'add' ? Icons.add : Icons.arrow_forward),
                      label: Text(action.label),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Page content - render widgets via RFW renderer.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RfwRenderer(
              widgets: page.widgets,
              actions: RfwActions(
                onNavigate: (route) {
                  widget.onNavigate(route);
                },
                onRowClick: (rowId) {
                  // Row click - no-op by default.
                },
                fetchData: (endpoint) async {
                  try {
                    // Prepend /v1/admin to the endpoint (matching Dash's
                    // RFW pattern). The RFW data_endpoint is relative
                    // (e.g. "/products") and the BFF proxy forwards to
                    // the service's /v1/admin/{endpoint} route.
                    final path = endpoint.startsWith('/v1/')
                        ? endpoint
                        : '/v1/admin$endpoint';
                    final resp = await widget.bffClient.get(path);
                    final data = resp.data;
                    if (data == null) return [];
                    if (data['data'] is List) {
                      return (data['data'] as List).cast<Map<String, dynamic>>();
                    }
                    // Some endpoints return a bare array or resource-keyed response.
                    if (data['products'] is List) {
                      return (data['products'] as List).cast<Map<String, dynamic>>();
                    }
                    if (data['accounts'] is List) {
                      return (data['accounts'] as List).cast<Map<String, dynamic>>();
                    }
                    return [data];
                  } catch (_) {
                    return [];
                  }
                },
                submitForm: (endpoint, body) async {
                  try {
                    final path = endpoint.startsWith('/')
                        ? endpoint
                        : '/v1/admin/$endpoint';
                    print('[Sentin8RfwPage] submitForm: path=$path, body keys=${body.keys.toList()}');
                    final resp = await widget.bffClient.post(path, body: body);
                    print('[Sentin8RfwPage] submitForm: status=${resp.statusCode}, isSuccess=${resp.isSuccess}, error=${resp.error}');
                    if (resp.data != null) {
                      return AdminUiResponse.fromJson(resp.data!);
                    }
                    return AdminUiResponse.error(resp.error ?? 'Request failed (status ${resp.statusCode})');
                  } catch (e, stack) {
                    print('[Sentin8RfwPage] submitForm error: $e');
                    print('[Sentin8RfwPage] submitForm stack: $stack');
                    return AdminUiResponse.error(e.toString());
                  }
                },
              ),
              extraProps: widget.extraProps,
            ),
          ),
        ),
      ],
    );
  }
}