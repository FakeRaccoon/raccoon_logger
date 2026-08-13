import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:raccoon/raccoon.dart';

/// Demo app for the raccoon inspector: fires a few sample calls, then lets you
/// open the inspector from the floating button.
///
/// Every request below is real, so the interesting cases (slow, 404, network
/// failure) come from endpoints that actually behave that way.
void main() {
  runApp(const ExampleApp());
}

final Dio _dio = Dio()..useRaccoon();
final http.Client _client = RaccoonHttpClient();

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raccoon Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      builder: Raccoon.overlay,
      home: HomePage(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _lastResult = 'No calls yet.';

  Future<void> _run(String label, Future<void> Function() call) async {
    setState(() => _lastResult = 'Running $label…');
    try {
      await call();
      setState(() => _lastResult = '$label finished.');
    } catch (e) {
      setState(() => _lastResult = '$label failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raccoon Example'),
        actions: [
          IconButton(
            tooltip: 'Toggle app brightness',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => widget.onThemeModeChanged(
              widget.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Fire some calls, then tap the raccoon button to open the '
            'inspector. The app theme toggle above is there to check the '
            'inspector against a light and a dark host.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _run(
                  'GET json (dio)',
                  () => _dio.get(
                    'https://jsonplaceholder.typicode.com/todos/1',
                  ),
                ),
                child: const Text('GET json (dio)'),
              ),
              FilledButton(
                onPressed: () => _run(
                  'POST json (dio)',
                  () => _dio.post(
                    'https://jsonplaceholder.typicode.com/posts',
                    data: {'title': 'raccoon', 'body': 'hello', 'userId': 1},
                  ),
                ),
                child: const Text('POST json (dio)'),
              ),
              FilledButton(
                onPressed: () => _run(
                  'GET json (http)',
                  () => _client.get(
                    Uri.parse('https://jsonplaceholder.typicode.com/users/2'),
                  ),
                ),
                child: const Text('GET json (http)'),
              ),
              FilledButton(
                onPressed: () => _run(
                  'GET html',
                  () => _dio.get('https://example.com'),
                ),
                child: const Text('GET html'),
              ),
              FilledButton(
                onPressed: () => _run(
                  'slow call (3s)',
                  () => _dio.get('https://httpbin.org/delay/3'),
                ),
                child: const Text('Slow call (3s)'),
              ),
              FilledButton(
                onPressed: () => _run(
                  '404',
                  () => _dio.get(
                    'https://jsonplaceholder.typicode.com/todos/does-not-exist',
                  ),
                ),
                child: const Text('404'),
              ),
              FilledButton(
                onPressed: () => _run(
                  '500',
                  () => _dio.get('https://httpbin.org/status/500'),
                ),
                child: const Text('500'),
              ),
              FilledButton(
                onPressed: () => _run(
                  'network failure',
                  () => _dio.get('https://raccoon.invalid/nope'),
                ),
                child: const Text('Network failure'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(_lastResult),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Raccoon().showInspector(context: context),
            icon: const Icon(Icons.list_alt),
            label: const Text('Open inspector'),
          ),
        ],
      ),
    );
  }
}
