import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/utils/raccoon_parser.dart';

void main() {
  group('generateCurlCommand', () {
    test('GET with headers', () {
      final options = RequestOptions(
        path: '/users',
        baseUrl: 'https://api.test',
        method: 'GET',
        headers: {'Authorization': 'Bearer x'},
      );

      final curl = RaccoonParser.generateCurlCommand(options);

      expect(curl, startsWith('curl -X GET'));
      expect(curl, contains('-H "Authorization: Bearer x"'));
      expect(curl, contains('"https://api.test/users"'));
    });

    test('POST with map body is JSON-encoded and quoted', () {
      final options = RequestOptions(
        path: '/login',
        baseUrl: 'https://api.test',
        method: 'POST',
        data: {'user': 'a'},
      );

      final curl = RaccoonParser.generateCurlCommand(options);

      expect(curl, contains("-d '{\"user\":\"a\"}'"));
    });

    test('FormData becomes --form flags', () {
      final options = RequestOptions(
        path: '/upload',
        baseUrl: 'https://api.test',
        method: 'POST',
        data: FormData.fromMap({'name': 'raccoon'}),
      );

      final curl = RaccoonParser.generateCurlCommand(options);

      expect(curl, contains('--form "name=raccoon"'));
    });
  });

  group('parseHeaders', () {
    test('stringifies dynamic values', () {
      final result = RaccoonParser.parseHeaders(
        headers: <String, dynamic>{'x': 1, 'y': true},
      );
      expect(result, {'x': '1', 'y': 'true'});
    });

    test('throws on invalid input', () {
      expect(
        () => RaccoonParser.parseHeaders(headers: 42),
        throwsArgumentError,
      );
    });
  });
}
