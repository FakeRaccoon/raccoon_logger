# Raccoon Logger

Raccoon Logger is a lightweight in-app HTTP inspector for Flutter applications. It plugs into your networking stack, collects request/response metadata, and renders an inspector UI that you can open at runtime to debug traffic without leaving the app.

## Features

- Capture Dio requests and responses (including errors, headers, form data, and cURL exports).
- Headless singleton service (`RaccoonService`) that you can observe or drive manually.
- Inspector overlay button you can drag, snap, and tap to open the log view.
- Search field inside the inspector to quickly filter calls by method, endpoint, host, or status.
- Detail screens for headers, payloads, and errors with copy-to-clipboard helpers.

## Requirements

| | Minimum |
|---|---|
| Dart SDK | 3.10.1 |
| Flutter SDK | 3.38.3 |
| iOS | 13 |
| Android | API 24 (Android 7.0) |
| macOS | 10.15 Catalina |
| Windows | 10 |
| Linux | Ubuntu 20.04 / Debian 10 |
| Web | Chrome 96, Firefox 99, Safari 15.6, Edge 96 |

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  raccoon:
    path: ../raccoon_logger # or your preferred source
```

Then run `flutter pub get`.

## Quick Start

### Setup (Universal Approach - Works for All Apps)

```dart
// 1. Create your Dio client with the interceptor
final dio = Dio()
  ..interceptors.add(RaccoonInterceptor());

// 2. Set up a navigator key (works with MaterialApp, GoRouter, etc.)
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Configure navigator provider - works everywhere!
    Raccoon().setNavigatorProvider(() => navigatorKey.currentState!);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      // or MaterialApp.router with navigatorKey parameter
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const RaccoonOverlayWidget(), // Draggable inspector button
          ],
        );
      },
    );
  }
}
```

That's it! The overlay button now works with **all Flutter navigation solutions**.

### Usage

- **Tap the floating button** to open the inspector
- **Drag the button** to reposition it (it snaps to edges)
- **Filter calls** by tapping the search icon in the inspector

### Configuration Options

**When you DON'T need `setNavigatorProvider`:**
- Placing `RaccoonOverlayWidget` inside a Scaffold/Screen (context has Navigator access)

**When you DO need `setNavigatorProvider`:**
- Router-based apps (GoRouter, Auto_route, Beamer, GetX, etc.)
- Placing overlay at app root (outside Navigator tree)
- Opening inspector programmatically without context

| Setup | Need setNavigatorProvider? |
|-------|---------------------------|
| MaterialApp with navigatorKey | ✅ No (if set up like above) |
| GoRouter / Auto_route | ✅ Yes (use rootNavigatorKey) |
| Inside Scaffold/Screen | ❌ No |
| App root (outside Navigator) | ✅ Yes |

**Discord Webhook for Slow API Calls:**
You can optionally receive Discord notifications when an API call is considered slow. This feature is activated only when you provide a Discord webhook URL.

```dart
Raccoon().setDiscordConfig(
  url: 'https://discord.com/api/webhooks/...',
  threshold: 1000, // Optional: default is 500ms
);
```

## Service API Cheatsheet

- `Raccoon().showInspector(context: context)` – opens the inspector UI (recommended: always provide context)
- `Raccoon().setNavigatorProvider(() => navigatorKey.currentState!)` – optional navigator provider for opening inspector without context
- `Raccoon().setDioInstance(dio)` – enables request replay functionality
- `Raccoon().setDiscordConfig(url: url, threshold: threshold)` – enables Discord notifications for slow API calls
- `Raccoon().calls` – read-only list of captured HTTP calls
- `Raccoon().isInspectorOpened` – listen for inspector visibility changes
- `Raccoon().listenable` – attach to a `ListenableBuilder`/`AnimatedBuilder` for custom dashboards
- `RaccoonService()` – underlying `ChangeNotifier` with `addCall`, `addResponse`, `addError`, `clearCalls` for direct access

## Compatibility

Raccoon Logger works universally with all Flutter navigation solutions:

- ✅ **MaterialApp** (traditional Navigator)
- ✅ **MaterialApp.router** (Navigator 2.0)
- ✅ **GoRouter**
- ✅ **Auto_route**
- ✅ **Beamer**
- ✅ **GetX**
- ✅ Any custom navigation solution

The context-based navigation approach works seamlessly with all frameworks. No special configuration required!

## Tips

- Avoid leaking captured traffic by calling `Raccoon().showInspector()` only from debug builds, or behind a feature flag.
- Use `RaccoonService().clearCalls()` (exposed via the trash icon in the inspector) to keep memory in check during long sessions.
- If you need advanced retention rules, extend `RaccoonService` and prune `_calls` as necessary before shipping to production.
- **Recommended**: Always provide `context` to `showInspector()` for maximum compatibility and simplicity.

## Contributing

Issues and pull requests are welcome! Please include reproduction steps, and if possible, failing tests when reporting bugs.
