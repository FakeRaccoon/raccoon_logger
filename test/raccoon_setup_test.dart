import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/raccoon.dart';

void main() {
  test(
    'useRaccoon attaches the interceptor and registers the replay client',
    () {
      final dio = Dio()..useRaccoon();

      expect(dio.interceptors.whereType<RaccoonInterceptor>(), hasLength(1));
      expect(RaccoonService().dioInstance, same(dio));
    },
  );

  testWidgets('Raccoon.overlay renders the app child and the overlay button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: Raccoon.overlay,
        home: const Text('app', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('app'), findsOneWidget);
    expect(find.byType(RaccoonOverlayWidget), findsOneWidget);
  });
}
