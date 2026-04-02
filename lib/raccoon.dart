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
  /// Works with **all navigation solutions** (MaterialApp, GetX, GoRouter,
  /// Auto_route, Beamer, etc.) with **zero configuration required**.
  ///
  /// Resolution priority:
  /// 1. **Context** — most explicit, works everywhere when provided.
  /// 2. **Navigator provider** — optional, set via [setNavigatorProvider].
  /// 3. **Auto-discovery** — falls back to walking the widget tree to find
  ///    a mounted [NavigatorState] automatically. This means calling
  ///    `showInspector()` with no arguments works out-of-the-box with GetX
  ///    and other routers that are above the context where the button lives.
  ///
  /// Example (no setup needed, works with GetX):
  /// ```dart
  /// Raccoon().showInspector();
  /// ```
  ///
  /// Example (with context for explicit control):
  /// ```dart
  /// Raccoon().showInspector(context: context);
  /// ```
  Future<void> showInspector({BuildContext? context}) =>
      _service.navigateToCallListScreen(context: context);

  /// Listenable that mirrors updates from the underlying [RaccoonService].
  Listenable get listenable => _service;

  /// Set a navigator provider for opening the inspector without context.
  ///
  /// This is OPTIONAL - most apps should just pass context to [showInspector].
  ///
  /// The provider function should return a [NavigatorState] when called.
  ///
  /// Example with MaterialApp:
  /// ```dart
  /// final navigatorKey = GlobalKey<NavigatorState>();
  /// MaterialApp(navigatorKey: navigatorKey, ...);
  /// Raccoon().setNavigatorProvider(() => navigatorKey.currentState!);
  /// ```
  ///
  /// Example with GoRouter:
  /// ```dart
  /// final rootNavigatorKey = GlobalKey<NavigatorState>();
  /// final router = GoRouter(navigatorKey: rootNavigatorKey, ...);
  /// Raccoon().setNavigatorProvider(() => rootNavigatorKey.currentState!);
  /// ```
  ///
  /// Example with GetX:
  /// ```dart
  /// // Option 1: Use GetX navigator key (if configured)
  /// Raccoon().setNavigatorProvider(() => Get.key.currentState!);
  ///
  /// // Option 2: Just use context (recommended)
  /// Raccoon().showInspector(context: context);
  /// ```
  void setNavigatorProvider(NavigatorState Function() provider) {
    _service.setNavigatorProvider(provider);
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

  /// Set a custom [ThemeData] to style the Raccoon inspector UI.
  ///
  /// When set, the inspector is wrapped in a [Theme] widget with this data,
  /// overriding the host app's active theme inside the inspector.
  /// Pass `null` to revert to inheriting the host app's theme.
  ///
  /// Example — dark theme:
  /// ```dart
  /// Raccoon().setTheme(ThemeData.dark());
  /// ```
  ///
  /// Example — custom color scheme:
  /// ```dart
  /// Raccoon().setTheme(
  ///   ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
  /// );
  /// ```
  ///
  /// Example — revert to host app theme:
  /// ```dart
  /// Raccoon().setTheme(null);
  /// ```
  void setTheme(ThemeData? theme) {
    _service.setTheme(theme);
  }
}
