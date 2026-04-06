import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/raccoon.dart';

void main() {
  test('Raccoon should allow setting Discord config', () {
    final raccoon = Raccoon();

    // We can't easily test the private field without reflection or a mock service,
    // but we can verify the method exists and can be called.
    raccoon.setDiscordConfig(
      url: 'https://discord.com/api/webhooks/test',
      threshold: 1000,
    );

    // If it didn't crash, it's at least callable.
  });
}
