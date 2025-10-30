import 'dart:collection';

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

  /// Opens the inspector UI, optionally scoped to the provided [context].
  Future<void> showInspector({BuildContext? context}) =>
      _service.navigateToCallListScreen(context: context);

  /// Listenable that mirrors updates from the underlying [RaccoonService].
  Listenable get listenable => _service;

  /// Global navigator key that should be wired into the host `MaterialApp`.
  GlobalKey<NavigatorState> get navigatorKey => _service.navigatorKey;
}
