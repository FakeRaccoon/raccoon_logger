import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class RaccoonConfiguration with EquatableMixin {
  final GlobalKey<NavigatorState>? navigatorKey;

  RaccoonConfiguration({
    GlobalKey<NavigatorState>? navigatorKey,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

  RaccoonConfiguration copyWith({
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return RaccoonConfiguration(
      navigatorKey: navigatorKey ?? this.navigatorKey,
    );
  }

  @override
  List<Object?> get props => [navigatorKey];
}
