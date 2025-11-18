import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';

import 'raccoon_service.dart';

/// Public facade around [RaccoonService] for quick access inside apps.
class Raccoon {
  Raccoon._internal();

  static final Raccoon _instance = Raccoon._internal();

  factory Raccoon() => _instance;

  final RaccoonService _service = RaccoonService();

  /// Snapshot of recorded calls. Use [listenable] to be notified when it changes.
  UnmodifiableListView<RaccoonHttpCall> get calls => _service.calls;

  /// Listen for inspector visibility changes.
  ValueListenable<bool> get isInspectorOpened =>
      _service.isInspectorOpenedListenable;

  /// Opens the inspector UI.
  ///
  /// **For MaterialApp (traditional navigation):**
  /// You can optionally provide a [context], or rely on the global navigator key
  /// assigned to `MaterialApp.navigatorKey`.
  ///
  /// **For MaterialApp.router:**
  /// You MUST provide a [context]. The inspector will work with any routing
  /// solution (GoRouter, AutoRoute, Beamer, etc.).
  ///
  /// Example:
  /// ```dart
  /// // Works with both MaterialApp and MaterialApp.router
  /// Raccoon().showInspector(context: context);
  /// ```
  Future<void> showInspector({BuildContext? context}) =>
      _service.navigateToCallListScreen(context: context);

  /// Listenable that mirrors updates from the underlying [RaccoonService].
  Listenable get listenable => _service;

  /// Set an external navigator key for MaterialApp.router integration.
  ///
  /// Use this when you have a GoRouter, AutoRoute, or other router solution
  /// with its own navigator key. This allows the inspector to use your
  /// router's navigator as a fallback when context is not available.
  ///
  /// Example with GoRouter:
  /// ```dart
  /// final rootNavigatorKey = GlobalKey<NavigatorState>();
  /// final router = GoRouter(
  ///   navigatorKey: rootNavigatorKey,
  ///   // ... routes
  /// );
  ///
  /// // In your app initialization:
  /// Raccoon().setNavigatorKey(rootNavigatorKey);
  /// ```
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _service.setNavigatorKey(key);
  }

  /// Set a Dio instance for replaying requests.
  ///
  /// This enables the request replay functionality in the detail view,
  /// allowing you to resend captured requests.
  ///
  /// Example:
  /// ```dart
  /// final dio = Dio()
  ///   ..interceptors.add(RaccoonInterceptor());
  ///
  /// // Enable request replay
  /// Raccoon().setDioInstance(dio);
  /// ```
  void setDioInstance(Dio dio) {
    _service.setDioInstance(dio);
  }

  /// Global navigator key that should be wired into the host `MaterialApp`.
  ///
  /// **Note:** This is only required for [MaterialApp] with traditional navigation.
  /// When using [MaterialApp.router], this key is not needed - just ensure you
  /// always provide a [BuildContext] when calling [showInspector].
  @Deprecated(
    'This is only needed for MaterialApp with traditional navigation. '
    'For MaterialApp.router, provide context when calling showInspector(). '
    'This property will be removed in a future version.',
  )
  // ignore: deprecated_member_use
  GlobalKey<NavigatorState> get navigatorKey => _service.navigatorKey;
}
