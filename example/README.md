# Raccoon Example

Demo app for previewing the inspector UI.

```sh
cd example
flutter run -d macos      # or: flutter run -d chrome
```

Tap the buttons to fire sample calls — JSON, HTML, slow, 404, 500, and a
network failure — then tap the floating raccoon button to open the inspector.

The app bar's brightness toggle switches the host app between light and dark,
which is the quickest way to check the inspector's **Use App Theme** setting
against both. The other themes live under **⋮ → Theme** inside the inspector.

Calls are real, so the demo needs a network connection. On the web target,
`example.com` is blocked by CORS; the `jsonplaceholder` and `httpbin` buttons
work everywhere.
