import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/raccoon.dart';

void main() {
  test('setDiscordConfig accepts url and threshold without throwing', () {
    expect(
      () => Raccoon().setDiscordConfig(
        url: 'https://discord.com/api/webhooks/test',
        threshold: 1000,
      ),
      returnsNormally,
    );
  });
}
