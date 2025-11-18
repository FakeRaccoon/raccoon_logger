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
/// **For MaterialApp (traditional navigation):**
/// Assign [navigatorKey] to your `MaterialApp.navigatorKey` to let the inspector
/// present itself even when no [BuildContext] is available.
///
/// **For MaterialApp.router:**
/// No setup needed - just ensure you always provide a [BuildContext] when calling
/// [navigateToCallListScreen]. The inspector will work with any routing solution
/// (GoRouter, AutoRoute, etc.) as long as context is provided.
class RaccoonService extends ChangeNotifier {
  RaccoonService._internal();

  static final RaccoonService _instance = RaccoonService._internal();

  factory RaccoonService() => _instance;

  static RaccoonService get instance => _instance;

  /// Global navigator key the host app can assign to `MaterialApp.navigatorKey`.
  /// Used as a fallback when [navigateToCallListScreen] is invoked without a
  /// [BuildContext].
  ///
  /// **Note:** This is only required for [MaterialApp] with traditional navigation.
  /// When using [MaterialApp.router], this key is not needed - just ensure you
  /// always provide a [BuildContext] when calling [navigateToCallListScreen].
  @Deprecated(
    'This is only needed for MaterialApp with traditional navigation. '
    'For MaterialApp.router, provide context when calling showInspector(). '
    'This property will be removed in a future version.',
  )
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Optional external navigator key for MaterialApp.router integration.
  /// Set this if you're using GoRouter or other router solutions and want
  /// to use a custom navigator key.
  GlobalKey<NavigatorState>? externalNavigatorKey;

  /// Optional Dio instance for replaying requests.
  /// Set this if you want to enable request replay functionality.
  Dio? _dioInstance;

  /// Set an external navigator key (e.g., from GoRouter's navigatorKey).
  /// This is useful when using MaterialApp.router and you want the inspector
  /// to use your router's navigator key as a fallback.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    externalNavigatorKey = key;
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
  /// are ignored. When [context] is omitted, the service falls back to
  /// [navigatorKey].
  Future<void> navigateToCallListScreen({BuildContext? context}) async {
    if (isInspectorOpened) {
      return;
    }

    final navigator = _resolveNavigator(context);
    if (navigator == null) {
      log('RaccoonService: Unable to find a Navigator to display the inspector.');
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
  NavigatorState? _resolveNavigator(BuildContext? context) {
    if (context != null) {
      final navigator = Navigator.maybeOf(context, rootNavigator: true);
      if (navigator != null) {
        return navigator;
      }
    }
    // Try external navigator key first (for MaterialApp.router)
    if (externalNavigatorKey?.currentState != null) {
      return externalNavigatorKey!.currentState;
    }
    // Fallback to deprecated navigatorKey (for MaterialApp)
    // ignore: deprecated_member_use
    return navigatorKey.currentState;
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
