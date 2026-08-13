import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/raccoon.dart';
import 'package:raccoon/raccoon_service.dart';

RaccoonHttpCall _call({int? status, int duration = 0, String? error}) =>
    RaccoonHttpCall(
      id: 1,
      duration: duration,
      response: RaccoonHttpResponse(status: status),
      error: error == null ? null : RaccoonHttpError(error: error),
    );

RaccoonAlert? _alertFor(
  RaccoonHttpCall call, {
  int threshold = 500,
  bool slowAlerts = true,
  bool errorAlerts = true,
}) => RaccoonService.alertFor(
  call,
  threshold: threshold,
  slowAlerts: slowAlerts,
  errorAlerts: errorAlerts,
);

void main() {
  test('setDiscordConfig accepts url and threshold without throwing', () {
    expect(
      () => Raccoon().setDiscordConfig(
        url: 'https://discord.com/api/webhooks/test',
        threshold: 1000,
        slowAlerts: false,
        errorAlerts: true,
      ),
      returnsNormally,
    );
  });

  group('alertFor', () {
    test('fast successful call triggers nothing', () {
      expect(_alertFor(_call(status: 200, duration: 10)), isNull);
    });

    test('slow successful call triggers a slow alert', () {
      expect(_alertFor(_call(status: 200, duration: 500)), RaccoonAlert.slow);
    });

    test('DioException, 4xx/5xx and no-response calls are errors', () {
      expect(
        _alertFor(_call(status: 500, duration: 10, error: 'boom')),
        RaccoonAlert.error,
      );
      expect(_alertFor(_call(status: 404, duration: 10)), RaccoonAlert.error);
      expect(_alertFor(_call(status: -1, duration: 10)), RaccoonAlert.error);
    });

    test('a slow failed call alerts once, as an error', () {
      expect(
        _alertFor(_call(status: 500, duration: 9000, error: 'boom')),
        RaccoonAlert.error,
      );
    });

    test('each switch mutes only its own kind', () {
      expect(
        _alertFor(_call(status: 200, duration: 900), slowAlerts: false),
        isNull,
      );
      expect(
        _alertFor(_call(status: 500, duration: 900), errorAlerts: false),
        isNull,
      );
      expect(
        _alertFor(_call(status: 500, duration: 900), slowAlerts: false),
        RaccoonAlert.error,
      );
    });

    test('a zero threshold disables slow alerts', () {
      expect(
        _alertFor(_call(status: 200, duration: 9000), threshold: 0),
        isNull,
      );
    });
  });
}
