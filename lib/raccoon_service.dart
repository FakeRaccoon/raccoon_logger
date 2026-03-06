import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/view/raccoon_view.dart';

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

  static RaccoonService get instance => _instance;

  /// Optional navigator provider for opening inspector without context.
  /// Set via [setNavigatorProvider] to provide a [NavigatorState] when needed.
  NavigatorState Function()? _navigatorProvider;

  /// Optional Dio instance for replaying requests.
  /// Set this if you want to enable request replay functionality.
  Dio? _dioInstance;

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

  /// Get the configured Dio instance for replaying requests.
  Dio? get dioInstance => _dioInstance;

  final List<RaccoonHttpCall> _calls = <RaccoonHttpCall>[];

  final ValueNotifier<bool> _isInspectorOpenedNotifier =
      ValueNotifier<bool>(false);

  /// Read-only view of captured calls in insertion order.
  UnmodifiableListView<RaccoonHttpCall> get calls =>
      UnmodifiableListView<RaccoonHttpCall>(_calls);

  /// Notifier that mirrors the current open/closed state of the inspector.
  ValueListenable<bool> get isInspectorOpenedListenable =>
      _isInspectorOpenedNotifier;

  bool get isInspectorOpened => _isInspectorOpenedNotifier.value;

  void addCall(RaccoonHttpCall call) {
    _calls.add(call);
    notifyListeners();
  }

  /// Add response to existing alice http call
  FutureOr<void> addResponse(RaccoonHttpResponse res, int requestId) async {
    final index = _calls.indexWhere((call) => call.id == requestId);

    if (index != -1) {
      final seed = _calls[index];
      final int duration = res.time.difference(seed.createdTime).inMilliseconds;
      _calls[index] = seed.copyWith(response: res, duration: duration);
      notifyListeners();
    } else {
      log('No call found with id $requestId to update the response.');
    }
  }

  /// Add error to existing alice http call
  FutureOr<void> addError(RaccoonHttpError error, int requestId) async {
    final index = _calls.indexWhere((call) => call.id == requestId);

    if (index != -1) {
      final seed = _calls[index];
      final int duration =
          DateTime.now().difference(seed.createdTime).inMilliseconds;
      _calls[index] = seed.copyWith(error: error, duration: duration);
      notifyListeners();
    } else {
      log('No call found with id $requestId to update the response.');
    }
  }

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
      log('RaccoonService: Unable to find a Navigator. '
          'Provide context or set up a navigator provider via setNavigatorProvider().');
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
