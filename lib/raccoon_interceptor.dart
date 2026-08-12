import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:raccoon/model/raccoon_form_data_field.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_form_data_file.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/utils/raccoon_body.dart';
import 'package:raccoon/utils/raccoon_parser.dart';

/// Reads `content-length` when the server sent one, so a large body can be
/// sized without being materialised.
int? _declaredSize(Headers headers) =>
    int.tryParse(headers.value(Headers.contentLengthHeader) ?? '');

/// Dio interceptor that captures requests, responses and errors into the
/// shared [RaccoonService] for inspection.
class RaccoonInterceptor extends InterceptorsWrapper {
  final RaccoonService service = RaccoonService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final call = RaccoonHttpCall(id: options.hashCode);
      var request = RaccoonHttpRequest();

      final uri = options.uri;

      var path = options.uri.path;

      if (path.isEmpty) {
        path = '/';
      }

      final dynamic data = options.data;

      if (data == null) {
        request = request.copyWith(size: 0, body: "");
      } else {
        if (data is FormData) {
          request = request.copyWith(body: "Form Data");

          if (data.fields.isNotEmpty == true) {
            final fields = <RaccoonFormDataField>[];
            for (var entry in data.fields) {
              fields.add(RaccoonFormDataField(entry.key, entry.value));
            }

            request = request.copyWith(formDataFields: fields);
          }

          if (data.files.isNotEmpty == true) {
            final files = <RaccoonHttpFormDataFile>[];
            for (var entry in data.files) {
              files.add(
                RaccoonHttpFormDataFile(
                  entry.value.filename,
                  entry.value.contentType.toString(),
                ),
              );
            }

            request = request.copyWith(formDataFiles: files);
          }
        } else {
          final captured = RaccoonBody.capture(data);
          request = request.copyWith(size: captured.size, body: captured.body);
        }
      }

      request = request.copyWith(
        time: DateTime.now(),
        headers: RaccoonParser.parseHeaders(headers: options.headers),
        contentType: options.contentType.toString(),
        curl: RaccoonParser.generateCurlCommand(options),
      );

      var seed = call.copyWith(
        method: options.method,
        endpoint: path,
        server: uri.host,
        uri: options.uri.toString(),
        request: request,
      );

      service.addCall(seed);
    } catch (e) {
      log("Raccoon: error on request: $e");
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      var httpResponse = RaccoonHttpResponse();

      final headers = <String, String>{};

      response.headers.forEach((header, values) {
        headers[header] = values.toString();
      });

      final captured = RaccoonBody.capture(
        response.data,
        declaredSize: _declaredSize(response.headers),
      );
      httpResponse = httpResponse.copyWith(
        body: captured.body,
        size: captured.size,
      );

      httpResponse = httpResponse.copyWith(
        status: response.statusCode,
        time: DateTime.now(),
        headers: headers,
      );

      service.addResponse(httpResponse, response.requestOptions.hashCode);
    } catch (e) {
      log("Raccoon: error on response: $e");
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      final httpError = RaccoonHttpError(
        error: err.toString(),
        stackTrace: err.stackTrace,
      );
      service.addError(httpError, err.requestOptions.hashCode);

      var httpResponse = RaccoonHttpResponse(time: DateTime.now());

      if (err.response == null) {
        httpResponse = httpResponse.copyWith(status: -1);
        service.addResponse(httpResponse, err.requestOptions.hashCode);
      } else {
        httpResponse = httpResponse.copyWith(status: err.response?.statusCode);

        final captured = RaccoonBody.capture(
          err.response!.data,
          declaredSize: _declaredSize(err.response!.headers),
        );
        httpResponse = httpResponse.copyWith(
          body: captured.body,
          size: captured.size,
        );

        final headers = <String, String>{};

        err.response!.headers.forEach((header, values) {
          headers[header] = values.toString();
        });

        httpResponse = httpResponse.copyWith(headers: headers);

        service.addResponse(
          httpResponse,
          err.response!.requestOptions.hashCode,
        );
      }
    } catch (e) {
      log("Raccoon: error on error: $e");
    }

    return handler.next(err);
  }
}
