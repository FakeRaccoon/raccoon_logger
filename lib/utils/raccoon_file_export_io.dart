import 'dart:io';

/// Writes [contents] next to the app's temporary files and returns the path.
///
/// The temp directory is the one location reachable without a plugin —
/// path_provider and share_plus are native plugins, and pulling either in
/// would cost every consumer of this package a platform dependency for a
/// debugging convenience.
// ponytail: temp dir keeps the package pure Dart; use exportHar() from the
// host app if you want it saved somewhere the user can browse to.
Future<String?> saveExportFile(String fileName, String contents) async {
  try {
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(contents);
    return file.path;
  } catch (e) {
    return null;
  }
}
