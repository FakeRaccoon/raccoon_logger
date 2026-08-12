import 'package:flutter/material.dart';
import 'package:raccoon/raccoon_service.dart';

/// Color themes the inspector UI can be rendered with.
///
/// [RaccoonThemePreset.app] inherits the host application's theme; every other
/// preset overrides it with a seeded [ColorScheme], so the inspector can be
/// read in a light theme while the app under test runs dark (or the reverse).
enum RaccoonThemePreset {
  app('Use App Theme', null, Brightness.light),
  basic('Basic', Color(0xFF3B7DD8), Brightness.light),
  clearDark('Clear Dark', Color(0xFF6EA8FF), Brightness.dark),
  clearLight('Clear Light', Color(0xFF3060A8), Brightness.light),
  grass('Grass', Color(0xFF3E8E41), Brightness.dark),
  homebrew('Homebrew', Color(0xFF28C940), Brightness.dark),
  manPage('Man Page', Color(0xFF8B6B29), Brightness.light),
  novel('Novel', Color(0xFF8B5A2B), Brightness.light),
  ocean('Ocean', Color(0xFF1E6FD9), Brightness.dark),
  pro('Pro', Color(0xFF9E9E9E), Brightness.dark),
  redSands('Red Sands', Color(0xFFC1553B), Brightness.dark);

  const RaccoonThemePreset(this.label, this.seed, this.brightness);

  /// Name shown in the picker.
  final String label;

  /// Seed for [ColorScheme.fromSeed]; `null` means "inherit the app theme".
  final Color? seed;

  final Brightness brightness;

  // ponytail: fromSeed builds a whole tonal palette, so cache per preset rather
  // than rebuilding on every list frame.
  static final Map<RaccoonThemePreset, ThemeData> _cache = {};

  /// The theme to render the inspector with, or `null` to keep the app's own.
  ThemeData? get themeData {
    final seedColor = seed;
    if (seedColor == null) {
      return null;
    }
    return _cache[this] ??= ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );
  }
}

/// Shows a snack bar painted with the inspector's own colors.
///
/// `ScaffoldMessenger` lives in the host app, above [RaccoonThemeScope], so a
/// snack bar raised from the inspector is themed by the app rather than by the
/// screen it came from — a white bar over a dark inspector. Passing the colors
/// explicitly keeps the two together.
void showRaccoonSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError ? colorScheme.onError : colorScheme.onSurface,
        ),
      ),
      backgroundColor: isError
          ? colorScheme.error
          : colorScheme.surfaceContainerHighest,
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ),
  );
}

/// Applies the inspector's selected [RaccoonThemePreset] to [child], and
/// rebuilds when the selection changes.
///
/// Wraps every inspector screen rather than the push site, so the theme holds
/// for screens pushed onto the host app's navigator.
class RaccoonThemeScope extends StatelessWidget {
  const RaccoonThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final service = RaccoonService();
    return ListenableBuilder(
      listenable: service,
      builder: (context, child) {
        final theme = service.themePreset.themeData;
        return theme == null ? child! : Theme(data: theme, child: child!);
      },
      child: child,
    );
  }
}
