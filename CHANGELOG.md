## 0.2.0

* **BREAKING CHANGE**: Simplified navigation API for universal compatibility
  * Removed deprecated `navigatorKey` getter - no longer needed
  * Removed `setNavigatorKey(GlobalKey)` method
  * Added `setNavigatorProvider(NavigatorState Function())` for optional navigator provider
  * Context-based navigation is now the primary and recommended approach
  * Navigator provider pattern is more flexible than GlobalKey approach

* **Improvement**: Unified navigation approach works seamlessly with all routing solutions
  * Single mental model: context-first, provider-optional
  * Navigator provider works with any NavigatorState source (MaterialApp, GoRouter, GetX, etc.)
  * Zero configuration needed for most apps - just use context
  * Works universally with MaterialApp, GoRouter, GetX, Auto_route, Beamer, and any custom navigation

* **Feature**: Request body now displayed in Headers tab
  * Added "Request Body" section to display JSON and text payloads
  * Automatically detects and formats request body content (String, Map, List, etc.)
  * Intelligently hides for empty requests and form data (shown separately)
  * Makes debugging POST/PUT/PATCH requests easier

* **Migration Guide** from 0.1.0:
  ```dart
  // OLD (0.1.0)
  MaterialApp(
    navigatorKey: Raccoon().navigatorKey,  // ❌ Removed
  )

  // NEW (0.2.0) - Option 1: Use context (recommended)
  // No setup needed! Just use context:
  Raccoon().showInspector(context: context);  // ✅

  // NEW (0.2.0) - Option 2: Navigator provider (optional)
  final navigatorKey = GlobalKey<NavigatorState>();
  MaterialApp(navigatorKey: navigatorKey);
  Raccoon().setNavigatorProvider(() => navigatorKey.currentState!);
  ```

  ```dart
  // OLD (0.1.0)
  Raccoon().setNavigatorKey(rootNavigatorKey);  // ❌ Removed

  // NEW (0.2.0)
  Raccoon().setNavigatorProvider(() => rootNavigatorKey.currentState!);  // ✅
  ```

## 0.1.0

* **Feature**: Added MaterialApp.router support (Navigator 2.0)
  * The package now works seamlessly with GoRouter, AutoRoute, Beamer, and other routing solutions
  * New `setNavigatorKey()` method allows injecting your router's navigator key for seamless integration
  * Context-based navigation is now the preferred approach
  * `navigatorKey` is deprecated but still supported for backward compatibility with traditional MaterialApp
  * Updated documentation with examples for both MaterialApp and MaterialApp.router
  * Added support for placing `RaccoonOverlayWidget` in MaterialApp.router's builder

* **Improvement**: Enhanced overlay button UX
  * The floating overlay button now automatically hides when the inspector is opened
  * Automatically shows again when the inspector is closed

* Initial release with core features:
  * Capture Dio requests and responses (including errors, headers, form data, and cURL exports)
  * Headless singleton service (`RaccoonService`) for data management
  * Draggable overlay button with inspector UI
  * Search functionality to filter calls by method, endpoint, host, or status code
  * Detail screens for headers, payloads, and errors with copy-to-clipboard helpers
