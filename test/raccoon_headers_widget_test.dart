import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/view/components/raccoon_headers_widget.dart';

void main() {
  testWidgets('section content is left-aligned, not centred in a wide window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RaccoonHeadersWidget(
            call: RaccoonHttpCall(
              id: 1,
              method: 'GET',
              endpoint: '/users/2',
              uri: 'https://jsonplaceholder.typicode.com/users/2',
              request: RaccoonHttpRequest(headers: const {'accept': '*/*'}),
              response: RaccoonHttpResponse(status: 200),
            ),
          ),
        ),
      ),
    );

    final sectionLeft = tester.getTopLeft(find.text('General')).dx;
    final rowLeft = tester.getTopLeft(find.text('Request URL: ')).dx;

    expect(rowLeft, closeTo(sectionLeft, 1));
  });

  testWidgets('header sections are hidden when there are none', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RaccoonHeadersWidget(
            call: RaccoonHttpCall(
              id: 1,
              method: 'GET',
              request: RaccoonHttpRequest(headers: const {'accept': '*/*'}),
              response: RaccoonHttpResponse(status: 200),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Request Headers'), findsOneWidget);
    expect(find.text('Response Headers'), findsNothing);
  });
}
