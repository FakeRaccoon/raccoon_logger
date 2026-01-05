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

### Setup (Works with all navigation solutions)

1. **Create your `Dio` client with the interceptor**

   ```dart
   final dio = Dio()
     ..interceptors.add(RaccoonInterceptor());
   ```

2. **Add the draggable inspector button**

   **For MaterialApp.router (GoRouter, Auto_route, etc.):**
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

   **For MaterialApp (traditional):**
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

3. **Open the inspector programmatically** (optional)

   ```dart
   ElevatedButton(
     onPressed: () => Raccoon().showInspector(context: context),
     child: const Text('Open Inspector'),
   )
   ```

That's it! The overlay button and context-based navigation work with **all Flutter navigation solutions** (MaterialApp, GoRouter, GetX, Auto_route, Beamer, etc.) with zero configuration.

### Advanced: Navigator Provider (Optional)

If you need to open the inspector without context (rare cases), you can set up a navigator provider:

```dart
// MaterialApp
final navigatorKey = GlobalKey<NavigatorState>();
MaterialApp(navigatorKey: navigatorKey, ...);
Raccoon().setNavigatorProvider(() => navigatorKey.currentState!);

// GoRouter
final rootNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(navigatorKey: rootNavigatorKey, ...);
Raccoon().setNavigatorProvider(() => rootNavigatorKey.currentState!);

// GetX - just use context (recommended)
Raccoon().showInspector(context: context);
```

### Usage

- **Filter captured calls** by tapping the search icon in the inspector's app bar. The inline search field matches method, endpoint, host, and status code so you can narrow noisy sessions quickly.

## Service API Cheatsheet

- `Raccoon().showInspector(context: context)` – opens the inspector UI (recommended: always provide context)
- `Raccoon().setNavigatorProvider(() => navigatorKey.currentState!)` – optional navigator provider for opening inspector without context
- `Raccoon().setDioInstance(dio)` – enables request replay functionality
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

Issues and pull requests are welcome! Please include reproduction steps and, if possible, failing tests when reporting bugs.
