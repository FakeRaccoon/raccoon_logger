import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/raccoon_theme.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';
import 'package:raccoon/utils/raccoon_file_export.dart';
import 'package:raccoon/utils/raccoon_har.dart';
import 'package:raccoon/view/raccoon_detail_view.dart';
import 'package:raccoon/view/raccoon_stats_view.dart';

/// Inspector home screen: a searchable list of captured calls with entry
/// points to the detail and statistics views.
class RaccoonView extends StatefulWidget {
  const RaccoonView({super.key, required this.service});

  final RaccoonService service;

  @override
  State<RaccoonView> createState() => _RaccoonViewState();
}

class _RaccoonViewState extends State<RaccoonView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim();
    if (value == _query) {
      return;
    }
    setState(() {
      _query = value;
    });
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) {
      return;
    }
    _searchController.clear();
  }

  void _toggleSearch() {
    if (_isSearching) {
      _searchFocusNode.unfocus();
      _clearSearch();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  /// Exports every completed call as HAR, to a file where the platform allows
  /// one and to the clipboard otherwise (or as well, when [copy] is set).
  Future<void> _exportHar({required bool copy}) async {
    final completed = widget.service.calls
        .where((c) => c.response != null)
        .length;
    if (completed == 0) {
      showRaccoonSnackBar(context, 'No calls to export');
      return;
    }

    final har = RaccoonHar.generate(widget.service.calls);
    if (copy) {
      await Clipboard.setData(ClipboardData(text: har));
      if (!mounted) return;
      showRaccoonSnackBar(context, 'Copied $completed call(s) as HAR');
      return;
    }

    final path = await saveExportFile('raccoon.har', har);
    if (!mounted) return;
    if (path == null) {
      // No file system to write to (web), so fall back rather than fail.
      await Clipboard.setData(ClipboardData(text: har));
      if (!mounted) return;
      showRaccoonSnackBar(
        context,
        'Saving files is not supported here — copied $completed call(s) instead',
        duration: const Duration(seconds: 4),
      );
      return;
    }
    _showSavedSheet(path, '$completed call(s) saved as HAR');
  }

  /// Shows where the file landed, with the path ready to paste into a terminal
  /// or a file picker — the package cannot open a share sheet without pulling
  /// in a native plugin.
  void _showSavedSheet(String path, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SelectableText(
                path,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: path));
                    showRaccoonSnackBar(context, 'Path copied');
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy path'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscordSettings() {
    final service = widget.service;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: AnimatedBuilder(
          animation: service,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Discord alerts'),
              ),
              if (!service.isDiscordConfigured)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'No webhook URL configured. Call '
                    'Raccoon().setDiscordConfig(url: ..., threshold: ...) '
                    'to enable notifications.',
                  ),
                ),
              SwitchListTile(
                value: service.discordSlowAlerts,
                onChanged: service.isDiscordConfigured
                    ? (value) => service.discordSlowAlerts = value
                    : null,
                title: const Text('Slow calls'),
                subtitle: Text(
                  service.slowCallThreshold > 0
                      ? 'Calls at or above ${service.slowCallThreshold} ms'
                      : 'Threshold is 0 ms — slow alerts never fire',
                ),
              ),
              SwitchListTile(
                value: service.discordErrorAlerts,
                onChanged: service.isDiscordConfigured
                    ? (value) => service.discordErrorAlerts = value
                    : null,
                title: const Text('Failed calls'),
                subtitle: const Text('Errors, timeouts, and 4xx/5xx responses'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    final service = widget.service;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: AnimatedBuilder(
          animation: service,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('Inspector theme'),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final preset in RaccoonThemePreset.values)
                      ListTile(
                        leading: _ThemeSwatch(preset: preset),
                        title: Text(preset.label),
                        subtitle: preset == RaccoonThemePreset.app
                            ? const Text('Follow the app you are debugging')
                            : null,
                        selected: preset == service.themePreset,
                        trailing: preset == service.themePreset
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => service.themePreset = preset,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesCall(RaccoonHttpCall call) {
    if (_query.isEmpty) {
      return true;
    }
    final normalizedQuery = _query.toLowerCase();
    final fields = <String?>[
      call.method,
      call.endpoint,
      call.server,
      call.uri,
      call.response?.status?.toString(),
      call.error?.error,
    ];
    return fields.any(
      (value) => value != null && value.toLowerCase().contains(normalizedQuery),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Builder, so the scaffold reads the theme the scope installs rather than
    // the app theme above it.
    return RaccoonThemeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onTapOutside: (event) => _searchFocusNode.unfocus(),
                decoration: const InputDecoration(
                  hintText: 'Search calls',
                  border: InputBorder.none,
                ),
              )
            : const Text('Raccoon View'),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'statistics') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RaccoonStatsView(service: widget.service),
                  ),
                );
              } else if (value == 'har') {
                _exportHar(copy: false);
              } else if (value == 'har-copy') {
                _exportHar(copy: true);
              } else if (value == 'discord') {
                _showDiscordSettings();
              } else if (value == 'theme') {
                _showThemePicker();
              } else if (value == 'clear') {
                widget.service.clearCalls();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'har',
                child: Row(
                  children: [
                    Icon(Icons.save_alt),
                    SizedBox(width: 8),
                    Text('Save all as HAR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'har-copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_all),
                    SizedBox(width: 8),
                    Text('Copy all as HAR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'discord',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined),
                    SizedBox(width: 8),
                    Text('Discord alerts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined),
                    SizedBox(width: 8),
                    Text('Theme'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.service,
        builder: (context, _) {
          final calls = widget.service.calls.reversed
              .where(_matchesCall)
              .toList(growable: false);

          if (calls.isEmpty) {
            return Center(
              child: Text(
                _query.isEmpty
                    ? 'There is no logged data'
                    : 'No calls match "$_query"',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              final brightness = Theme.of(context).brightness;
              final statusColor = RaccoonFormatHelpers.statusCodeColor(
                call.response?.status,
                brightness: brightness,
              );
              return ListTile(
                title: Text(
                  "${call.method} ${call.endpoint}",
                  style: TextStyle(
                    color: call.error != null
                        ? RaccoonFormatHelpers.tone(Colors.red, brightness)
                        : null,
                  ),
                ),
                isThreeLine: true,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(call.server),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${call.createdTime}"),
                        Row(
                          children: [
                            if (call.duration >= 500)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(<double>[
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                                  child: Text(
                                    '🐢',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            Text("${call.duration} ms"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: call.response?.status == null
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 5),
                      )
                    : Text(
                        "${call.response?.status}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                onTap: call.response?.status == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RaccoonDetailView(call: call),
                        ),
                      ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(height: 1);
            },
          );
        },
      ),
    );
  }
}

/// Miniature preview of a theme preset: a "terminal window" painted in that
/// preset's surface, text and accent colors.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.preset});

  final RaccoonThemePreset preset;

  @override
  Widget build(BuildContext context) {
    final scheme =
        preset.themeData?.colorScheme ?? Theme.of(context).colorScheme;

    Widget bar(Color color, double widthFactor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(height: 3, color: color),
    );

    return Container(
      width: 46,
      height: 32,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          bar(scheme.primary, 1),
          bar(scheme.onSurface, 0.55),
          bar(scheme.secondary, 0.8),
        ],
      ),
    );
  }
}
