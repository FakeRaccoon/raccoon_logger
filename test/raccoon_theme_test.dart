import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/raccoon.dart';
import 'package:raccoon/raccoon_theme.dart';
import 'package:raccoon/view/raccoon_view.dart';

void main() {
  final service = RaccoonService();

  tearDown(() => service.themePreset = RaccoonThemePreset.app);

  test('the app preset keeps the host theme, others override it', () {
    expect(RaccoonThemePreset.app.themeData, isNull);
    expect(
      RaccoonThemePreset.homebrew.themeData?.colorScheme.brightness,
      Brightness.dark,
    );
    expect(
      RaccoonThemePreset.manPage.themeData?.colorScheme.brightness,
      Brightness.light,
    );
  });

  testWidgets('snack bars follow the inspector theme, not the host app', (
    tester,
  ) async {
    final inspectorTheme = ThemeData(brightness: Brightness.dark);

    await tester.pumpWidget(
      MaterialApp(
        // Host app is light; the inspector screen below renders dark.
        theme: ThemeData(brightness: Brightness.light),
        home: Theme(
          data: inspectorTheme,
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showRaccoonSnackBar(context, 'copied'),
                child: const Text('copy'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('copy'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snackBar.backgroundColor,
      inspectorTheme.colorScheme.surfaceContainerHighest,
    );
  });

  testWidgets('picking a preset repaints the inspector', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: RaccoonView(service: service),
      ),
    );

    ThemeData themeOfList() =>
        Theme.of(tester.element(find.text('There is no logged data')));

    expect(themeOfList().brightness, Brightness.light);

    service.themePreset = RaccoonThemePreset.homebrew;
    await tester.pump();

    // The inspector now renders dark while the host app stays light.
    expect(themeOfList().brightness, Brightness.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme?.brightness,
      Brightness.light,
    );
  });
}
