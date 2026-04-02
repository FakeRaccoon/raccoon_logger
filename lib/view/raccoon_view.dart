import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/view/raccoon_detail_view.dart';
import 'package:raccoon/view/raccoon_stats_view.dart';

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
              return ListTile(
                title: Text(
                  "${call.method} ${call.endpoint}",
                  style: TextStyle(
                    color: call.error != null ? Colors.red : null,
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
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0,      0,      0,      1, 0,
                                  ]),
                                  child: Text('🐢', style: TextStyle(fontSize: 12)),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : Text(
                        "${call.response?.status}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: call.error != null ? Colors.red : Colors.green,
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
              return const Divider(color: Colors.grey);
            },
          );
        },
      ),
    );
  }
}
