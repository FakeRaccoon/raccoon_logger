/// Writing files needs `dart:io`, which the web build does not have, so the
/// web falls back to the clipboard.
Future<String?> saveExportFile(String fileName, String contents) async => null;
