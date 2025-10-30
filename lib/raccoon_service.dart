import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/view/raccoon_view.dart';

/// Singleton backing store for captured HTTP calls and inspector state.
///
/// The service implements [ChangeNotifier] so widgets can listen for updates.
/// Assign [navigatorKey] to your `MaterialApp` to let the inspector present
/// itself even when no [BuildContext] is available.
class RaccoonService extends ChangeNotifier {
  RaccoonService._internal();

  static final RaccoonService _instance = RaccoonService._internal();

  factory RaccoonService() => _instance;

  static RaccoonService get instance => _instance;

  /// Global navigator key the host app should assign to `MaterialApp.navigatorKey`.
  /// Used as a fallback when [navigateToCallListScreen] is invoked without a
  /// [BuildContext].
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    return navigatorKey.currentState;
  }

  void _setInspectorOpened(bool value) {
    if (_isInspectorOpenedNotifier.value == value) {
      return;
    }
    _isInspectorOpenedNotifier.value = value;
    notifyListeners();
  }
}
