import 'package:flutter/material.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/view/raccoon_view.dart';

/// A self-contained shell that hosts all Raccoon inspector screens inside
/// its own [Navigator].
///
/// Wrapping raccoon pages in their own navigator means:
/// - Sub-pages pushed from within raccoon (detail, stats) stay inside this
///   shell and are automatically covered by the [Theme] wrapper.
/// - The host app's navigator stack is not polluted by raccoon's sub-routes.
///
/// When [themeData] is non-null, the entire shell is wrapped in a [Theme]
/// widget using that data, overriding whatever theme the host app uses.
class RaccoonShell extends StatelessWidget {
  const RaccoonShell({
    super.key,
    required this.service,
    this.themeData,
  });

  final RaccoonService service;
  final ThemeData? themeData;

  @override
  Widget build(BuildContext context) {
    Widget shell = Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => RaccoonView(service: service),
      ),
    );

    if (themeData != null) {
      shell = Theme(data: themeData!, child: shell);
    }

    return shell;
  }
}
