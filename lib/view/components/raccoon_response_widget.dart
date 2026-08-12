import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_theme.dart';
import 'package:raccoon/utils/raccoon_formatter.dart';

/// Response tab: renders a call's response body with a Formatted/Raw toggle,
/// find-in-page search, and JSON/XML/image/text handling.
class RaccoonResponseWidget extends StatefulWidget {
  const RaccoonResponseWidget({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  State<RaccoonResponseWidget> createState() => _RaccoonResponseWidgetState();
}

class _RaccoonResponseWidgetState extends State<RaccoonResponseWidget> {
  bool _showFormatted = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  int _activeMatch = 0;

  /// Match offsets and the laid-out span of the last build, kept so the
  /// next/previous buttons can scroll without rebuilding the body themselves.
  List<int> _matches = const [];
  TextSpan? _renderedSpan;
  double _renderedWidth = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
      _activeMatch = 0;
    });
    _scrollToActiveMatch();
  }

  void _stepMatch(int delta) {
    if (_matches.isEmpty) {
      return;
    }
    setState(() {
      // Wrap around, like a browser's find bar.
      _activeMatch = (_activeMatch + delta) % _matches.length;
      if (_activeMatch < 0) {
        _activeMatch += _matches.length;
      }
    });
    _scrollToActiveMatch();
  }

  /// Scrolls the active match into view.
  ///
  /// Measures with a [TextPainter] over the same span and width the body is
  /// rendered at, so the offset is exact even when long lines wrap.
  void _scrollToActiveMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final span = _renderedSpan;
      if (span == null ||
          _matches.isEmpty ||
          _renderedWidth <= 0 ||
          !_scrollController.hasClients) {
        return;
      }

      final painter = TextPainter(
        text: span,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: _renderedWidth);

      final caret = painter.getOffsetForCaret(
        TextPosition(offset: _matches[_activeMatch]),
        Rect.zero,
      );
      final position = _scrollController.position;
      // Park the match a third of the way down rather than at the very top.
      final target = (caret.dy - position.viewportDimension / 3).clamp(
        0.0,
        position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.call.response?.body == null) {
      return const Center(child: Text("There is no response"));
    }

    final body = widget.call.response!.body;
    final headers = widget.call.response!.headers;
    final contentType = RaccoonFormatter.detectContentType(headers, body);
    final colorScheme = Theme.of(context).colorScheme;

    // Resolve the body and its matches before laying anything out: the find
    // bar above the body needs the match count from the same build.
    final (text, baseSpans) = contentType == 'image'
        ? ('', const <TextSpan>[])
        : _resolveBody(contentType, body);
    _matches = RaccoonFormatter.findMatches(text, _query);
    if (_activeMatch >= _matches.length) {
      _activeMatch = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              if (contentType == 'json' || contentType == 'xml') ...[
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text(
                          'Formatted',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.code, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Raw', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.text_fields, size: 16),
                      ),
                    ],
                    selected: {_showFormatted},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showFormatted = newSelection.first;
                      });
                    },
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: body.toString()));
                  showRaccoonSnackBar(context, 'Response copied to clipboard');
                },
                icon: const Icon(Icons.copy),
                tooltip: 'Copy response',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (contentType != 'image') _buildSearchBar(colorScheme),
        Expanded(
          child: contentType == 'image'
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildImageContent(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _renderedWidth = constraints.maxWidth - 32;
                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: _buildBody(baseSpans),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final hasMatches = _matches.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _stepMatch(1),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search response',
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_query.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              hasMatches ? '${_activeMatch + 1}/${_matches.length}' : '0/0',
              style: TextStyle(
                color: hasMatches
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: hasMatches ? () => _stepMatch(-1) : null,
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous match',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: hasMatches ? () => _stepMatch(1) : null,
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next match',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  /// The body as plain text plus its syntax-highlighted spans. The two always
  /// describe the same characters, so match offsets map onto both.
  (String, List<TextSpan>) _resolveBody(String contentType, dynamic body) {
    final brightness = Theme.of(context).brightness;
    try {
      if (contentType == 'json' && _showFormatted) {
        final text = RaccoonFormatter.formatJson(body);
        return (text, RaccoonFormatter.jsonSpans(text, brightness));
      }
      if ((contentType == 'xml' || contentType == 'html') && _showFormatted) {
        final text = RaccoonFormatter.formatXml(body.toString());
        return (text, RaccoonFormatter.xmlSpans(text, brightness));
      }
    } catch (e) {
      // Fall through to the unhighlighted text below.
    }
    final text = body.toString();
    return (text, [TextSpan(text: text)]);
  }

  /// Paints the find-in-page highlights over [baseSpans].
  Widget _buildBody(List<TextSpan> baseSpans) {
    final spans = RaccoonFormatter.highlightMatches(
      baseSpans,
      query: _query,
      activeIndex: _activeMatch,
      color: Colors.yellow.withValues(alpha: 0.3),
      activeColor: Colors.orange.withValues(alpha: 0.7),
    );

    final span = TextSpan(style: RaccoonFormatter.bodyStyle, children: spans);
    _renderedSpan = span;

    return SelectableText.rich(span);
  }

  Widget _buildImageContent() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 64, color: muted),
          const SizedBox(height: 16),
          Text(
            'Image preview not yet supported',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Check the Headers tab for image metadata',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
