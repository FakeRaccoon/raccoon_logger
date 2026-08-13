/// Saves an export to a file where the platform allows it.
///
/// `saveExportFile` returns the written path, or `null` when the platform has
/// no file system the package can reach (the web build) or the write failed —
/// callers fall back to the clipboard.
library;

export 'raccoon_file_export_stub.dart'
    if (dart.library.io) 'raccoon_file_export_io.dart';
