# Raccoon Logger

Raccoon Logger is a lightweight in-app HTTP inspector for Flutter applications. It plugs into your networking stack, collects request/response metadata, and renders an inspector UI that you can open at runtime to debug traffic without leaving the app.

## Features

- Capture Dio requests and responses (including errors, headers, form data, and cURL exports).
- Headless singleton service (`RaccoonService`) that you can observe or drive manually.
- Inspector overlay button you can drag, snap, and tap to open the log view.
- Search field inside the inspector to quickly filter calls by method, endpoint, host, or status.
- Detail screens for headers, payloads, and errors with copy-to-clipboard helpers.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  raccoon:
    path: ../raccoon_logger # or your preferred source
```

Then run `flutter pub get`.

## Quick Start

1. **Create your `Dio` client with the interceptor**

   ```dart
   final dio = Dio()
     ..interceptors.add(RaccoonInterceptor());
   ```

2. **Wire the global navigator key** so Raccoon can open the inspector outside of widget trees.

   ```dart
   class App extends StatelessWidget {
     App({super.key});

     final _raccoon = Raccoon();

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         navigatorKey: _raccoon.navigatorKey,
         home: const HomePage(),
       );
     }
   }
   ```

3. **Drop the draggable inspector button** somewhere near the top of your `MaterialApp` to access the UI with a tap.

   ```dart
   class HomePage extends StatelessWidget {
     const HomePage({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         body: Stack(
           children: const [
             // ... your content ...
             RaccoonOverlayWidget(),
           ],
         ),
       );
     }
   }
   ```

4. **Open the inspector on demand** (optional), for example from a debug gesture or menu item.

   ```dart
   ElevatedButton(
     onPressed: () => Raccoon().showInspector(context: context),
     child: const Text('Open inspector'),
   )
   ```

5. **Filter captured calls** by tapping the search icon in the inspector's app bar. The inline search field matches method, endpoint, host, and status code so you can narrow noisy sessions quickly.

## Service API Cheatsheet

- `Raccoon()` – singleton facade exposing `calls`, `isInspectorOpened`, and `navigatorKey`.
- `RaccoonService()` – underlying `ChangeNotifier` with `addCall`, `addResponse`, `addError`, `clearCalls`, and `navigateToCallListScreen` if you need direct access.
- `Raccoon().listenable` – attach to a `ListenableBuilder`/`AnimatedBuilder` for custom dashboards.

## Tips

- Avoid leaking captured traffic by calling `Raccoon().showInspector()` only from debug builds, or behind a feature flag.
- Use `RaccoonService().clearCalls()` (exposed via the trash icon in the inspector) to keep memory in check during long sessions.
- If you need advanced retention rules, extend `RaccoonService` and prune `_calls` as necessary before shipping to production.

## Contributing

Issues and pull requests are welcome! Please include reproduction steps and, if possible, failing tests when reporting bugs.
