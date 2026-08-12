import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/raccoon_theme.dart';
import 'package:raccoon/view/raccoon_view.dart';

/// Kinds of Discord notification Raccoon can post for a finished call.
enum RaccoonAlert { slow, error }

/// Singleton backing store for captured HTTP calls and inspector state.
///
/// The service implements [ChangeNotifier] so widgets can listen for updates.
///
/// **Navigation:**
/// Always provide a [BuildContext] when calling [navigateToCallListScreen] for
/// best compatibility with all navigation solutions (MaterialApp, GoRouter, GetX,
/// Auto_route, Beamer, etc.).
///
/// Optionally, set a [NavigatorState] provider via [setNavigatorProvider] for
/// cases where context is not available.
class RaccoonService extends ChangeNotifier {
  RaccoonService._internal();

  static final RaccoonService _instance = RaccoonService._internal();

  factory RaccoonService() => _instance;

  /// Maximum number of calls retained. Oldest are dropped past this cap to
  /// keep memory bounded in long-running sessions.
  // ponytail: fixed ring cap, expose a setter only if someone asks for it.
  static const int _maxCalls = 1000;

  /// Optional navigator provider for opening inspector without context.
  /// Set via [setNavigatorProvider] to provide a [NavigatorState] when needed.
  NavigatorState Function()? _navigatorProvider;

  /// Optional Dio instance for replaying requests.
  /// Set this if you want to enable request replay functionality.
  Dio? _dioInstance;

  /// Optional Discord webhook URL for slow call notifications.
  String? _discordWebhookUrl;

  /// Threshold in milliseconds for slow call notifications. `0` disables them.
  int _slowCallThreshold = 0;

  bool _discordSlowAlerts = true;
  bool _discordErrorAlerts = true;

  RaccoonThemePreset _themePreset = RaccoonThemePreset.app;

  /// Color theme the inspector UI renders with. Defaults to the host app's
  /// theme; changing it rebuilds the open inspector screens.
  RaccoonThemePreset get themePreset => _themePreset;

  set themePreset(RaccoonThemePreset value) {
    if (_themePreset == value) {
      return;
    }
    _themePreset = value;
    notifyListeners();
  }

  /// Set a navigator provider for opening the inspector without context.
  ///
  /// This is OPTIONAL - most apps should just pass context to
  /// [navigateToCallListScreen].
  ///
  /// The provider function should return a [NavigatorState] when called.
  ///
  /// Example with MaterialApp:
  /// ```dart
  /// final navigatorKey = GlobalKey<NavigatorState>();
  /// RaccoonService().setNavigatorProvider(() => navigatorKey.currentState!);
  /// ```
  ///
  /// Example with GoRouter:
  /// ```dart
  /// final rootNavigatorKey = GlobalKey<NavigatorState>();
  /// RaccoonService().setNavigatorProvider(() => rootNavigatorKey.currentState!);
  /// ```
  void setNavigatorProvider(NavigatorState Function() provider) {
    _navigatorProvider = provider;
  }

  /// Set a Dio instance for replaying requests.
  /// This allows the inspector to resend captured requests.
  ///
  /// Example:
  /// ```dart
  /// final dio = Dio();
  /// RaccoonService().setDioInstance(dio);
  /// ```
  void setDioInstance(Dio dio) {
    _dioInstance = dio;
  }

  /// Set Discord webhook configuration for call notifications.
  ///
  /// [url] is the Discord webhook URL.
  /// [threshold] is the duration in milliseconds at or above which a call is
  /// considered slow. Pass `0` to never alert on slow calls.
  /// [slowAlerts] and [errorAlerts] set the initial state of the two switches
  /// in the inspector's Discord settings sheet.
  void setDiscordConfig({
    required String url,
    required int threshold,
    bool slowAlerts = true,
    bool errorAlerts = true,
  }) {
    _discordWebhookUrl = url;
    _slowCallThreshold = threshold;
    _discordSlowAlerts = slowAlerts;
    _discordErrorAlerts = errorAlerts;
    notifyListeners();
  }

  /// Whether a Discord webhook URL has been configured.
  bool get isDiscordConfigured => _discordWebhookUrl != null;

  /// Duration in milliseconds at or above which a call counts as slow.
  int get slowCallThreshold => _slowCallThreshold;

  /// Whether slow calls trigger a Discord notification.
  bool get discordSlowAlerts => _discordSlowAlerts;

  set discordSlowAlerts(bool value) {
    if (_discordSlowAlerts == value) {
      return;
    }
    _discordSlowAlerts = value;
    notifyListeners();
  }

  /// Whether failed calls trigger a Discord notification.
  bool get discordErrorAlerts => _discordErrorAlerts;

  set discordErrorAlerts(bool value) {
    if (_discordErrorAlerts == value) {
      return;
    }
    _discordErrorAlerts = value;
    notifyListeners();
  }

  /// Get the configured Dio instance for replaying requests.
  Dio? get dioInstance => _dioInstance;

  final List<RaccoonHttpCall> _calls = <RaccoonHttpCall>[];

  final ValueNotifier<bool> _isInspectorOpenedNotifier = ValueNotifier<bool>(
    false,
  );

  /// Read-only view of captured calls in insertion order.
  UnmodifiableListView<RaccoonHttpCall> get calls =>
      UnmodifiableListView<RaccoonHttpCall>(_calls);

  /// Notifier that mirrors the current open/closed state of the inspector.
  ValueListenable<bool> get isInspectorOpenedListenable =>
      _isInspectorOpenedNotifier;

  bool get isInspectorOpened => _isInspectorOpenedNotifier.value;

  void addCall(RaccoonHttpCall call) {
    _calls.add(call);
    if (_calls.length > _maxCalls) {
      _calls.removeAt(0);
    }
    notifyListeners();
  }

  /// Add response to existing alice http call
  FutureOr<void> addResponse(RaccoonHttpResponse res, int requestId) async {
    final index = _calls.indexWhere((call) => call.id == requestId);

    if (index != -1) {
      final seed = _calls[index];
      final int duration = res.time.difference(seed.createdTime).inMilliseconds;
      final updatedCall = seed.copyWith(response: res, duration: duration);
      _calls[index] = updatedCall;
      notifyListeners();
      _sendDiscordNotification(updatedCall);
    } else {
      log('No call found with id $requestId to update the response.');
    }
  }

  /// Add error to existing alice http call
  FutureOr<void> addError(RaccoonHttpError error, int requestId) async {
    final index = _calls.indexWhere((call) => call.id == requestId);

    if (index != -1) {
      final seed = _calls[index];
      final int duration = DateTime.now()
          .difference(seed.createdTime)
          .inMilliseconds;
      final updatedCall = seed.copyWith(error: error, duration: duration);
      _calls[index] = updatedCall;
      notifyListeners();
      // Discord notification is fired from addResponse only; every terminal
      // path (success or error) also calls addResponse, so notifying here too
      // would double-post.
    } else {
      log('No call found with id $requestId to update the response.');
    }
  }

  /// Decides which Discord alert (if any) a finished call should trigger.
  ///
  /// Returns [RaccoonAlert.error] for failed calls, [RaccoonAlert.slow] for
  /// calls at or above [threshold], and `null` when neither applies or the
  /// matching switch is off. Errors win when a call is both failed and slow, so
  /// a call never posts twice.
  @visibleForTesting
  static RaccoonAlert? alertFor(
    RaccoonHttpCall call, {
    required int threshold,
    required bool slowAlerts,
    required bool errorAlerts,
  }) {
    final status = call.response?.status;
    // status == -1 is the interceptor's marker for "request never got a
    // response" (timeout, DNS, connection refused).
    final isError =
        call.error != null || status == -1 || (status != null && status >= 400);
    if (isError) {
      return errorAlerts ? RaccoonAlert.error : null;
    }
    if (slowAlerts && threshold > 0 && call.duration >= threshold) {
      return RaccoonAlert.slow;
    }
    return null;
  }

  /// Sends a Discord notification when a finished call matches an enabled alert.
  Future<void> _sendDiscordNotification(RaccoonHttpCall call) async {
    final url = _discordWebhookUrl;
    if (url == null) {
      return;
    }

    final alert = alertFor(
      call,
      threshold: _slowCallThreshold,
      slowAlerts: _discordSlowAlerts,
      errorAlerts: _discordErrorAlerts,
    );
    if (alert == null) {
      return;
    }

    final isError = alert == RaccoonAlert.error;

    try {
      final dio = Dio();
      await dio.post(
        url,
        data: {
          "embeds": [
            {
              "title": isError
                  ? "🦝 API Error Detected"
                  : "🦝 Slow API Call Detected",
              "color": isError ? 15548997 : 16753920, // Red : Orange
              "fields": [
                {
                  "name": "Endpoint",
                  "value": "`${call.method} ${call.endpoint}`",
                  "inline": false,
                },
                {
                  "name": "Duration",
                  "value": "`${call.duration}ms`",
                  "inline": true,
                },
                {
                  "name": "Status",
                  "value": "`${call.response?.status ?? 'Error'}`",
                  "inline": true,
                },
                {
                  "name": "Server",
                  "value": "`${call.server}`",
                  "inline": false,
                },
                if (call.error != null)
                  {
                    "name": "Error",
                    // Discord rejects embed field values over 1024 chars.
                    "value": _truncate(call.error!.error, 1000),
                    "inline": false,
                  },
                if (call.request?.curl != null)
                  {
                    "name": "cURL",
                    "value": "```\n${_truncate(call.request!.curl, 980)}\n```",
                    "inline": false,
                  },
              ],
              "timestamp": DateTime.now().toIso8601String(),
            },
          ],
        },
      );
    } catch (e) {
      log('RaccoonService: Failed to send Discord notification: $e');
    }
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…';

  /// Clears all captured calls and notifies listeners.
  void clearCalls() {
    if (_calls.isEmpty) {
      return;
    }
    _calls.clear();
    notifyListeners();
  }

  /// Opens the inspector UI. Subsequent calls while the inspector is visible
  /// are ignored.
  ///
  /// **Recommended:** Always provide [context] for maximum compatibility with
  /// all navigation solutions (MaterialApp, GoRouter, GetX, Auto_route, etc.).
  ///
  /// **Optional:** If context is not available, set a navigator provider via
  /// [setNavigatorProvider] first.
  Future<void> navigateToCallListScreen({BuildContext? context}) async {
    if (isInspectorOpened) {
      return;
    }

    final navigator = _resolveNavigator(context);
    if (navigator == null) {
      log(
        'RaccoonService: Unable to find a Navigator. '
        'Provide context or set up a navigator provider via setNavigatorProvider().',
      );
      return;
    }

    _setInspectorOpened(true);
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => RaccoonView(service: this),
          fullscreenDialog: true,
        ),
      );
    } finally {
      _setInspectorOpened(false);
    }
  }

  /// Chooses the most appropriate navigator available for displaying screens.
  ///
  /// Priority order:
  /// 1. Context-based navigator (works with all navigation solutions)
  /// 2. Navigator provider (optional, set via [setNavigatorProvider])
  /// 3. Auto-discovery from the widget tree (zero-config fallback)
  NavigatorState? _resolveNavigator(BuildContext? context) {
    // Priority 1: Context-based (works with everything)
    if (context != null) {
      final navigator = Navigator.maybeOf(context, rootNavigator: true);
      if (navigator != null) {
        return navigator;
      }
    }

    // Priority 2: Navigator provider (optional convenience)
    if (_navigatorProvider != null) {
      try {
        return _navigatorProvider!();
      } catch (e) {
        log('Navigator provider failed: $e');
      }
    }

    // Priority 3: Auto-discover from widget tree.
    // This is a zero-config fallback that works with GetX, GoRouter, and
    // any other navigation solution — no setup required.
    return _discoverNavigator();
  }

  /// Walks the widget tree from the root to find the deepest mounted
  /// [NavigatorState]. Prefer the deepest (most nested) navigator to avoid
  /// pushing on a parent overlay that may be obscured.
  ///
  /// This traversal only runs when neither a [BuildContext] nor a navigator
  /// provider resolves a navigator, so performance impact is negligible.
  NavigatorState? _discoverNavigator() {
    NavigatorState? result;
    void visitor(Element element) {
      if (element is StatefulElement && element.state is NavigatorState) {
        result = element.state as NavigatorState;
      }
      element.visitChildElements(visitor);
    }

    WidgetsBinding.instance.rootElement?.visitChildElements(visitor);
    return result;
  }

  void _setInspectorOpened(bool value) {
    if (_isInspectorOpenedNotifier.value == value) {
      return;
    }
    _isInspectorOpenedNotifier.value = value;
    notifyListeners();
  }

  /// Replays a captured HTTP call using the configured Dio instance.
  ///
  /// Returns a [Response] if successful, or throws a [DioException] on error.
  /// Throws [StateError] if no Dio instance has been configured.
  Future<Response> replayRequest(RaccoonHttpCall call) async {
    if (_dioInstance == null) {
      throw StateError(
        'No Dio instance configured. Call setDioInstance() first.',
      );
    }

    if (call.request == null) {
      throw StateError('Cannot replay request: request data is null');
    }

    final request = call.request!;

    // Prepare request options
    final options = Options(
      method: call.method,
      headers: request.headers,
      contentType: request.contentType,
    );

    // Parse query parameters from URI
    final uri = Uri.parse(call.uri);
    final queryParameters = uri.queryParameters;

    // Prepare request data
    dynamic data = request.body;
    if (request.body == "Form Data" && request.formDataFields != null) {
      final formData = FormData();
      for (final field in request.formDataFields!) {
        formData.fields.add(MapEntry(field.name, field.value));
      }
      data = formData;
    }

    // Execute the request
    return _dioInstance!.request(
      call.uri,
      data: data,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      options: options,
    );
  }
}
