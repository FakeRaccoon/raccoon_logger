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
