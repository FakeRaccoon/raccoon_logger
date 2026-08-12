import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/utils/raccoon_body.dart';

void main() {
  test('small bodies are kept whole, with their byte size', () {
    final captured = RaccoonBody.capture('héllo');

    expect(captured.body, 'héllo');
    expect(captured.size, utf8.encode('héllo').length); // 6, not 5
  });

  test('a decoded map keeps its structure and is sized as JSON', () {
    final captured = RaccoonBody.capture({'a': 1});

    expect(captured.body, {'a': 1});
    expect(captured.size, '{"a":1}'.length);
  });

  test('an oversized string is truncated but reports its real size', () {
    final big = 'x' * (RaccoonBody.maxBytes + 500);
    final captured = RaccoonBody.capture(big);

    expect(captured.size, RaccoonBody.maxBytes + 500);
    expect((captured.body as String).length, lessThan(big.length));
    expect(captured.body, contains('truncated'));
  });

  test('a declared size over the cap skips the body entirely', () {
    final captured = RaccoonBody.capture(
      // A body that would be ruinous to stringify; it must not be touched.
      _Explosive(),
      declaredSize: 5 * 1024 * 1024,
    );

    expect(captured.size, 5 * 1024 * 1024);
    expect(captured.body, '<body not captured: 5.0 MB>');
  });

  test('a declared size is trusted instead of re-measuring', () {
    final captured = RaccoonBody.capture('abc', declaredSize: 3);

    expect(captured.body, 'abc');
    expect(captured.size, 3);
  });

  test('null bodies capture as empty', () {
    expect(RaccoonBody.capture(null), (body: '', size: 0));
  });
}

/// Fails the test if anything tries to stringify or encode it.
class _Explosive {
  @override
  String toString() {
    fail('an oversized body must not be stringified');
  }

  Object toJson() {
    fail('an oversized body must not be encoded');
  }
}
