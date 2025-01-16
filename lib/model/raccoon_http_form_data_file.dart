/// Definition of data holder of form data file.
class RaccoonHttpFormDataFile {
  const RaccoonHttpFormDataFile(
    this.fileName,
    this.contentType,
    this.length,
  );

  final String? fileName;
  final String contentType;
  final int length;
}
