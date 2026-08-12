import 'package:equatable/equatable.dart';
import 'package:raccoon/model/raccoon_form_data_field.dart';
import 'package:raccoon/model/raccoon_http_form_data_file.dart';

/// Definition of http request data holder.
class RaccoonHttpRequest with Equatable {
  RaccoonHttpRequest({
    this.size = 0,
    DateTime? time,
    this.headers = const <String, String>{},
    this.body = '',
    this.contentType = '',
    this.curl = '',
    this.formDataFiles,
    this.formDataFields,
  }) : time = time ?? DateTime.now();

  final int size;
  final DateTime? time;
  final Map<String, String> headers;
  final dynamic body;
  final String? contentType;
  final String curl;
  final List<RaccoonHttpFormDataFile>? formDataFiles;
  final List<RaccoonFormDataField>? formDataFields;

  RaccoonHttpRequest copyWith({
    int? size,
    DateTime? time,
    Map<String, String>? headers,
    dynamic body,
    String? contentType,
    String? curl,
    List<RaccoonHttpFormDataFile>? formDataFiles,
    List<RaccoonFormDataField>? formDataFields,
  }) {
    return RaccoonHttpRequest(
      size: size ?? this.size,
      time: time ?? this.time,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      contentType: contentType ?? this.contentType,
      curl: curl ?? this.curl,
      formDataFiles: formDataFiles ?? this.formDataFiles,
      formDataFields: formDataFields ?? this.formDataFields,
    );
  }

  @override
  List<Object?> get props => [
    size,
    time,
    headers,
    body,
    contentType,
    formDataFiles,
    formDataFields,
  ];
}
