# Raccoon Logger

Raccoon Logger is a lightweight in-app HTTP inspector for Flutter applications. It plugs into your networking stack, collects request/response metadata, and renders an inspector UI that you can open at runtime to debug traffic without leaving the app.

## Features

- Capture Dio and `package:http` requests and responses (including errors, headers, form data, and cURL exports).
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

## Preview It

The `example/` app fires sample calls (JSON, HTML, slow, 404, 500, network failure) so you can see the inspector without wiring it into your own app first:

```sh
cd example
flutter run -d macos      # or: flutter run -d chrome
```

## Quick Start

Two lines. No navigator key, no `Stack` boilerplate.

```dart
import 'package:dio/dio.dart';
import 'package:raccoon/raccoon.dart';

// 1. Wire your Dio client (adds the interceptor + enables request replay)
final dio = Dio()..useRaccoon();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 2. Add the draggable inspector button
    return MaterialApp(
      builder: Raccoon.overlay,
      home: const HomePage(),
    );
  }
}
```

Works the same with `MaterialApp.router`, GoRouter, Auto_route, Beamer, and GetX — the inspector finds the active `Navigator` on its own.

### Using `package:http`

Wrap your client instead of adding an interceptor — everything sent through it is captured:

```dart
final client = RaccoonHttpClient();

await client.get(Uri.parse('https://example.com/todos'));
```

`RaccoonHttpClient` also wraps an existing client (`RaccoonHttpClient(myClient)`), so it composes with retry/auth clients you already use. Both clients can be active at once; captured calls land in the same inspector.

Two caveats: response bodies are buffered so the inspector can show them, so a streamed download is fully read into memory; and request replay runs through Dio, so `http`-only apps need `Raccoon().setDioInstance(Dio())` for the replay button to work.

### Usage

- **Tap the floating button** to open the inspector
- **Drag the button** to reposition it (it snaps to edges)
- **Filter calls** by tapping the search icon in the inspector

### Advanced

**Already using `builder`?** Nest the widget yourself:

```dart
MaterialApp(
  builder: (context, child) => Stack(
    children: [?child, const RaccoonOverlayWidget()],
  ),
);
```

**Opening the inspector from your own code:**

```dart
Raccoon().showInspector(context: context); // context is optional
```

**Navigator auto-discovery failing?** (custom navigator setups, multiple roots) Point Raccoon at your key explicitly:

```dart
Raccoon().setNavigatorProvider(() => navigatorKey.currentState!);
```

**Separate client for replay?** `dio.useRaccoon()` registers the capturing client. Override with `Raccoon().setDioInstance(otherDio)`.

### Exporting

**⋮ → Save all as HAR** writes `raccoon.har` next to the app's temporary files and shows the path; **Copy all as HAR** puts the same document on the clipboard. The Statistics screen's download button does both for its Markdown report. On the web there is no file system the package can reach, so saving falls back to copying.

Raccoon deliberately has no share-sheet integration: that needs a native plugin, and this package stays pure Dart. Take the report and hand it to whatever your app already uses:

```dart
await Share.shareXFiles([
  XFile.fromData(utf8.encode(Raccoon().exportHar()), name: 'raccoon.har'),
]);
```

### Theme

**⋮ → Theme** picks the color theme for the inspector UI: **Use App Theme** (default) inherits the host application's theme, and the presets — Basic, Clear Dark, Grass, Homebrew, Man Page, Novel, Ocean, Pro, Red Sands — override it, so you can read the inspector in light while the app under test runs dark.

Set it from code if you want a fixed theme:

```dart
RaccoonService().themePreset = RaccoonThemePreset.homebrew;
```

The choice lasts for the session; it is not persisted across restarts.

### Discord Alerts

Add a webhook URL and Raccoon posts an embed when a call is **slow** or **fails**. Notifications are off entirely until a URL is set.

```dart
Raccoon().setDiscordConfig(
  url: 'https://discord.com/api/webhooks/...',
  threshold: 1000,     // slow = at or above 1000 ms; 0 disables slow alerts
  slowAlerts: true,    // optional, defaults to true
  errorAlerts: true,   // optional, defaults to true
);
```

Both alert kinds have a switch under **⋮ → Discord alerts** in the inspector, so you can mute one without touching code — handy when a known-slow endpoint is flooding the channel.

| Alert | Fires on | Embed |
|---|---|---|
| Slow calls | Successful call with `duration >= threshold` | Orange |
| Failed calls | `DioException`, timeout/no response, or 4xx/5xx status | Red, includes the error |

A call that is both slow and failed posts once, as an error. Every embed carries method, endpoint, duration, status, server, and the cURL command.

## Service API Cheatsheet

- `dio.useRaccoon()` – attaches the interceptor and enables request replay
- `RaccoonHttpClient([inner])` – `package:http` client wrapper that captures every call sent through it
- `Raccoon.overlay` – drop-in `MaterialApp.builder` that renders the inspector button
- `Raccoon().showInspector(context: context)` – opens the inspector UI (`context` optional)
- `Raccoon().setNavigatorProvider(() => navigatorKey.currentState!)` – optional; only when auto-discovery fails
- `Raccoon().setDioInstance(dio)` – optional; only when the replay client differs from the capturing one
- `Raccoon().setDiscordConfig(url: url, threshold: threshold)` – enables Discord notifications for slow and failed calls
- `Raccoon().exportHar()` – every completed call as a HAR 1.2 document
- `Raccoon().exportStatsMarkdown()` – the statistics report as Markdown
- `RaccoonService().themePreset` – color theme for the inspector UI (`RaccoonThemePreset.app` follows the host app)
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
