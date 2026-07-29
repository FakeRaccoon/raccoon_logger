import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';

void main() {
  group('formatBytes', () {
    test('scales across units', () {
      expect(RaccoonFormatHelpers.formatBytes(512), '512 B');
      expect(RaccoonFormatHelpers.formatBytes(2048), '2.0 KB');
      expect(RaccoonFormatHelpers.formatBytes(5 * 1024 * 1024), '5.0 MB');
    });
  });

  test('formatDuration appends ms', () {
    expect(RaccoonFormatHelpers.formatDuration(1300), '1300 ms');
  });

  test('formatTime zero-pads', () {
    expect(
      RaccoonFormatHelpers.formatTime(DateTime(2026, 1, 1, 9, 5, 3)),
      '09:05:03',
    );
  });

  group('getStatusMessage', () {
    test('known and ranged codes', () {
      expect(RaccoonFormatHelpers.getStatusMessage(null), 'Pending');
      expect(RaccoonFormatHelpers.getStatusMessage(-1), 'Failed');
      expect(RaccoonFormatHelpers.getStatusMessage(200), 'OK');
      expect(RaccoonFormatHelpers.getStatusMessage(418), 'Client Error');
      expect(RaccoonFormatHelpers.getStatusMessage(599), 'Server Error');
    });
  });

  group('colors', () {
    test('statusCodeColor', () {
      expect(RaccoonFormatHelpers.statusCodeColor(null), Colors.red);
      expect(RaccoonFormatHelpers.statusCodeColor(-1), Colors.red);
      expect(RaccoonFormatHelpers.statusCodeColor(204), Colors.green);
      expect(RaccoonFormatHelpers.statusCodeColor(302), Colors.blue);
      expect(RaccoonFormatHelpers.statusCodeColor(404), Colors.orange);
      expect(RaccoonFormatHelpers.statusCodeColor(500), Colors.red);
    });

    test('methodColor is case-insensitive', () {
      expect(RaccoonFormatHelpers.methodColor('get'), Colors.blue);
      expect(RaccoonFormatHelpers.methodColor('POST'), Colors.green);
      expect(RaccoonFormatHelpers.methodColor('WEIRD'), Colors.grey);
    });
  });
}
