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

### Option A: MaterialApp (Traditional Navigation)

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

### Option B: MaterialApp.router (Navigator 2.0)

1. **Create your `Dio` client with the interceptor** (same as above)

   ```dart
   final dio = Dio()
     ..interceptors.add(RaccoonInterceptor());
   ```

2. **Set up your router and assign the navigator key to Raccoon**

   ```dart
   final rootNavigatorKey = GlobalKey<NavigatorState>();

   final router = GoRouter(
     navigatorKey: rootNavigatorKey,
     routes: [
       // your routes
     ],
   );

   class App extends StatefulWidget {
     const App({super.key});

     @override
     State<App> createState() => _AppState();
   }

   class _AppState extends State<App> {
     @override
     void initState() {
       super.initState();
       // IMPORTANT: Set the router's navigator key to Raccoon
       Raccoon().setNavigatorKey(rootNavigatorKey);
     }

     @override
     Widget build(BuildContext context) {
       return MaterialApp.router(
         routerConfig: router,
       );
     }
   }
   ```

3. **Drop the draggable inspector button** using the builder (recommended for global overlay)

   ```dart
   MaterialApp.router(
     routerConfig: router,
     builder: (context, child) {
       return Stack(
         children: [
           child!,
           const RaccoonOverlayWidget(),
         ],
       );
     },
   )
   ```

   Or place it in individual pages:

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

4. **Open the inspector on demand** - context is optional if you set the navigator key

   ```dart
   ElevatedButton(
     onPressed: () => Raccoon().showInspector(), // context optional!
     child: const Text('Open inspector'),
   )
   ```

### General Usage

- **Filter captured calls** by tapping the search icon in the inspector's app bar. The inline search field matches method, endpoint, host, and status code so you can narrow noisy sessions quickly.

## Service API Cheatsheet

- `Raccoon()` – singleton facade exposing `calls`, `isInspectorOpened`, and `showInspector()`.
- `Raccoon().navigatorKey` – _(deprecated)_ only needed for `MaterialApp` with traditional navigation. Not required for `MaterialApp.router`.
- `RaccoonService()` – underlying `ChangeNotifier` with `addCall`, `addResponse`, `addError`, `clearCalls`, and `navigateToCallListScreen` if you need direct access.
- `Raccoon().listenable` – attach to a `ListenableBuilder`/`AnimatedBuilder` for custom dashboards.

## Compatibility

Raccoon Logger supports both traditional navigation and Navigator 2.0:

- **MaterialApp (traditional)**: Works with optional `navigatorKey` or always providing `context`
- **MaterialApp.router**: Works seamlessly with GoRouter, AutoRoute, Beamer, and other routing solutions - just always provide `context` when calling `showInspector()`
- The package automatically detects and uses the appropriate navigator from the widget tree

## Tips

- Avoid leaking captured traffic by calling `Raccoon().showInspector()` only from debug builds, or behind a feature flag.
- Use `RaccoonService().clearCalls()` (exposed via the trash icon in the inspector) to keep memory in check during long sessions.
- If you need advanced retention rules, extend `RaccoonService` and prune `_calls` as necessary before shipping to production.
- **For MaterialApp.router users**: Always pass `context` to `showInspector()` to ensure proper navigation.

## Contributing

Issues and pull requests are welcome! Please include reproduction steps and, if possible, failing tests when reporting bugs.
