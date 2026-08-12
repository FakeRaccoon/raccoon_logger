## 0.6.0

### Breaking changes

* **Removed unused public model fields** that were never surfaced in the UI:
  `RaccoonHttpCall.{client, loading, secure}`,
  `RaccoonHttpRequest.{cookies, queryParameters}`,
  `RaccoonHttpFormDataFile.length`.
  `RaccoonHttpRequest.cookies` was the source of a `dart:io` import that broke
  web builds. Read query parameters from `RaccoonHttpCall.uri` instead; drop
  references to the other fields — none of them were populated with anything the
  inspector displayed.
* **`RaccoonHttpFormDataFile` positional argument removed** — the constructor is
  now `RaccoonHttpFormDataFile(fileName, contentType)`; the trailing `length`
  argument no longer exists.

* **Discord notification behaviour changed** (signatures are unchanged, so this
  is source-compatible but will alter what lands in your channel):
  failed calls now notify by default — pass `errorAlerts: false` to
  `setDiscordConfig` to keep the 0.5.0 slow-only behaviour — and a `threshold`
  of `0` now disables slow alerts instead of alerting on every call.

Nothing else changed shape: `Raccoon()`, `RaccoonInterceptor`,
`RaccoonOverlayWidget`, `setNavigatorProvider`, `setDioInstance` and
`setDiscordConfig` all keep their 0.5.0 signatures. The new setup helpers below
are additive — existing wiring keeps working.

### Improvements

* **`package:http` support.** `RaccoonHttpClient` is a `BaseClient` wrapper that
  captures requests, responses and errors into the same inspector as the Dio
  interceptor — including multipart fields/files and cURL export:

  ```dart
  final client = RaccoonHttpClient();          // or RaccoonHttpClient(myClient)

  await client.get(Uri.parse('https://example.com/todos'));
  ```

  Both clients can be used side by side. Response bodies are buffered so the
  inspector can display them, so streamed downloads are read into memory in
  full. Request replay still runs through Dio — `http`-only apps need
  `Raccoon().setDioInstance(Dio())` for the replay button. Adds a dependency on
  `http: ^1.2.0`.
* **Two-line setup.** `dio.useRaccoon()` attaches the interceptor and registers
  the client for request replay in one call, and `Raccoon.overlay` is a
  drop-in `MaterialApp.builder` that renders the draggable button — no
  navigator key and no hand-written `Stack` required:

  ```dart
  final dio = Dio()..useRaccoon();

  MaterialApp(builder: Raccoon.overlay, home: const HomePage());
  ```

  `setNavigatorProvider` is now documented as a fallback for the rare cases
  where navigator auto-discovery can't find a mounted `NavigatorState`.
* **Discord alerts for failed calls, toggleable in-app.** The webhook now fires
  for errors (`DioException`, timeouts, and 4xx/5xx responses) as well as slow
  calls, with a red embed carrying the error message. Each kind has its own
  switch under **⋮ → Discord alerts** in the inspector, and initial state can be
  set from code:

  ```dart
  Raccoon().setDiscordConfig(
    url: '...',
    threshold: 1000,
    slowAlerts: true,
    errorAlerts: true,
  );
  ```

  A call that is both slow and failed posts once, as an error. A `threshold` of
  `0` now means "never alert on slow calls" instead of "alert on everything".
  Long error and cURL values are truncated to stay under Discord's 1024-char
  embed field limit.
* **Find-in-page search for responses.** The Response tab has a search field
  that highlights every match in the body, with a `2/7` counter and
  previous/next buttons that scroll each hit into view and wrap around at the
  ends — the behaviour of a mobile browser's find bar. Highlights compose with
  the JSON/XML syntax colors, and a match is highlighted correctly even when it
  straddles two syntax tokens. Works on formatted JSON/XML and on raw or
  plain-text bodies.
* **Empty header sections are hidden** instead of expanding to nothing, and the
  Headers tab no longer centres its content in a wide window.
* **Theme picker.** **⋮ → Theme** opens a list of color themes for the
  inspector UI — Basic, Clear Dark, Grass, Homebrew, Man Page, Novel, Ocean,
  Pro, Red Sands — each previewed by a swatch. The default, **Use App Theme**,
  keeps the previous behaviour of inheriting the host application's theme, so
  the inspector can be read in light while the app under test runs dark. The
  choice can also be set from code with
  `RaccoonService().themePreset = RaccoonThemePreset.homebrew` and lasts for the
  session (not persisted across restarts).
* **Dark mode fixes across the inspector.** Status, method and duration colors
  now pick the shade that stays legible on the current theme (the light 300
  shade on dark surfaces, the dark 700 shade on light ones) instead of a fixed
  Material 500. The response toolbar, replay dialog and dividers use theme
  surfaces rather than hardcoded greys, so they no longer render as bright
  strips on a dark background.
* **XML/HTML highlighting no longer swallows text.** Any line starting with `<`
  used to be painted entirely as a tag, so `<title>403 Forbidden</title>`
  rendered the message in tag color; tags and content are now highlighted
  separately.
* **HAR export** — the inspector can copy all captured calls as a HAR 1.2
  document for import into browser devtools or Charles/Proxyman.

### Fixes

* **Fix**: Error stack traces are now captured. The previous `err is Error`
  check was always false for `DioException`; the interceptor now uses
  `err.stackTrace` directly.
* **Fix**: A single slow failed call no longer posts to Discord twice. The
  notification is sent from one place (`addResponse`) only.
* **Fix**: `onError` is now wrapped in try/catch so a parse failure can't break
  Dio's error chain.
* **Fix**: Web builds no longer break — removed the unused `dart:io` `Cookie`
  import (and the dead `cookies` field it required).
* **Fix**: Guarded force-unwraps in the Headers tab and detail view that could
  throw for a call with no response yet.
* **Improvement**: Captured calls are now capped at 1000 (oldest dropped) to
  keep memory bounded in long sessions.
* **Improvement**: One import (`package:raccoon/raccoon.dart`) now re-exports
  the public API (`Raccoon`, `RaccoonInterceptor`, `RaccoonOverlayWidget`,
  `RaccoonService`, `RaccoonHttpCall`).
* **Chore**: Dropped the `expandable` dependency (Headers sections now use the
  SDK's `ExpansionTile`); bumped `flutter_lints` to `^6.0.0`; removed dead code
  and consolidated duplicated status/method color helpers.

## 0.5.0

* **Improvement**: Statistics screen UI overhaul
  * Overview restructured into a 2-row grid (Total/Success/Failed + Avg/Slow/Transfer) — no more truncated labels
  * Success, Failed, and Slow values are color-coded when non-zero
  * Transfer data (sent/received) promoted into the overview grid
  * Section headers now have a small vertical accent bar for visual hierarchy
  * Distribution bars taller (5px) with rounded corners; percentage and count shown in separate columns
  * Endpoint and slow-request progress bars bumped to 3px

* **Improvement**: Duration formatting always uses ms
  * All durations across the app are now displayed in milliseconds (e.g. `1300 ms` instead of `1.30 s`)

* **Feature**: Export statistics as Markdown
  * Download button in the Statistics app bar generates a full `.md` report
  * Includes overview table, status codes, methods, endpoints, slow requests, and failed requests
  * Report is shown in a copyable bottom sheet with one-tap clipboard copy

* **Improvement**: Discord webhook — cURL command included in notification
  * Slow API call embeds now include the full cURL command for easy reproduction
  * cURL field is omitted if request data is unavailable

* **Breaking**: Discord config requires explicit `threshold` — no more default 500ms
  * Both `url` and `threshold` are now required in `Raccoon().setDiscordConfig()`
  * Ensures notifications are never sent without intentional configuration

## 0.4.0

* **Feature**: Discord Webhook for Slow API Calls
  * Added optional Discord notification system for slow API calls
  * Configurable threshold (default: 500ms) for determining slow calls
  * Sends rich Discord embeds with method, endpoint, duration, status, and server details
  * Background execution ensures no impact on application performance
  * Activated only when a Discord webhook URL is provided via `Raccoon().setDiscordConfig()`

## 0.3.0

* **BREAKING CHANGE**: Bumped minimum SDK and platform requirements
  * Dart SDK: `>=3.10.1`
  * Flutter SDK: `>=3.38.3`
  * iOS: 13+
  * Android: API 24 (Android 7.0 Nougat)+
  * macOS: 10.15 Catalina+
  * Windows: 10+
  * Linux: Ubuntu 20.04 LTS+ / Debian 10+
  * Web: Chrome 96+, Firefox 99+, Safari 15.6+, Edge 96+

* **Feature**: Auto-discover navigator from widget tree as zero-config fallback
  * Inspector can now open without any navigator setup in most apps

* **Feature**: Expanded Statistics screen
  * Per-endpoint aggregation with avg, min, and max duration per unique endpoint
  * Timeline bar chart showing request activity over time, with error buckets highlighted in red
  * Data transfer totals showing total bytes sent and received
  * Slow requests list (>500ms) sorted by duration with proportional bar indicator
  * Failed requests list (4xx/5xx and network errors) with tappable rows navigating to detail view

* **Improvement**: Slow API indicator in request list
  * Requests taking longer than 500ms are marked with a 🐢 icon (monochrome) next to the duration

* **Improvement**: Minimalistic Statistics UI
  * Replaced colored stat cards with a compact inline overview row
  * Thinner progress bars, removed card/border decoration from list items
  * Section headers use smaller label style with inline subtitles
  * Colors adapt to light/dark theme via `colorScheme`

* **Improvement**: Request body in Headers tab is now rendered as `SelectableText`
  * Users can now select and copy request body content directly from the UI
  * Replaces the previous non-selectable `RaccoonRowWidget` layout

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
