import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';

import 'raccoon_interceptor.dart';
import 'raccoon_service.dart';
import 'view/components/raccoon_draggable_overlay_widget.dart';

// Barrel: one import (`package:raccoon/raccoon.dart`) exposes the full public
// API instead of deep file paths.
export 'package:raccoon/raccoon_http_client.dart' show RaccoonHttpClient;
export 'package:raccoon/raccoon_interceptor.dart' show RaccoonInterceptor;
export 'package:raccoon/raccoon_service.dart' show RaccoonService;
export 'package:raccoon/raccoon_theme.dart' show RaccoonThemePreset;
export 'package:raccoon/model/raccoon_http_call.dart' show RaccoonHttpCall;
export 'package:raccoon/view/components/raccoon_draggable_overlay_widget.dart'
    show RaccoonOverlayWidget;

/// Public facade around [RaccoonService] for quick access inside apps.
///
/// Minimal setup:
/// ```dart
/// final dio = Dio()..useRaccoon();
///
/// MaterialApp(builder: Raccoon.overlay, home: const HomePage());
/// ```
class Raccoon {
  Raccoon._internal();

  static final Raccoon _instance = Raccoon._internal();

  factory Raccoon() => _instance;

  final RaccoonService _service = RaccoonService();

  /// Ready-made [MaterialApp.builder] that stacks the draggable inspector
  /// button over the app.
  ///
  /// ```dart
  /// MaterialApp(builder: Raccoon.overlay, home: const HomePage());
  /// ```
  ///
  /// Apps that already use `builder` can nest [RaccoonOverlayWidget] in their
  /// own `Stack` instead.
  static Widget overlay(BuildContext context, Widget? child) =>
      Stack(children: [?child, const RaccoonOverlayWidget()]);

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
  /// Prefer `dio.useRaccoon()`, which attaches the interceptor and registers
  /// the instance in one call. Use this only when the capturing client and the
  /// replay client differ.
  void setDioInstance(Dio dio) {
    _service.setDioInstance(dio);
  }

  /// Set Discord webhook configuration for slow and failed call notifications.
  ///
  /// [url] is the Discord webhook URL.
  /// [threshold] is the duration in milliseconds at or above which a call is
  /// considered slow; `0` disables slow alerts.
  /// [slowAlerts] and [errorAlerts] set the initial state of the two switches
  /// in the inspector's Discord settings sheet.
  ///
  /// Example:
  /// ```dart
  /// Raccoon().setDiscordConfig(
  ///   url: 'https://discord.com/api/webhooks/...',
  ///   threshold: 500,
  /// );
  /// ```
  void setDiscordConfig({
    required String url,
    required int threshold,
    bool slowAlerts = true,
    bool errorAlerts = true,
  }) {
    _service.setDiscordConfig(
      url: url,
      threshold: threshold,
      slowAlerts: slowAlerts,
      errorAlerts: errorAlerts,
    );
  }
}

/// One-call wiring for a [Dio] client.
extension RaccoonDio on Dio {
  /// Attaches [RaccoonInterceptor] and registers this client for request
  /// replay.
  ///
  /// ```dart
  /// final dio = Dio()..useRaccoon();
  /// ```
  void useRaccoon() {
    interceptors.add(RaccoonInterceptor());
    RaccoonService().setDioInstance(this);
  }
}
