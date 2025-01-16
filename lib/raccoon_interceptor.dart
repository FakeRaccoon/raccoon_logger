import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:raccoon/model/raccoon_form_data_field.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_form_data_file.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/raccoon_adapter.dart';
import 'package:raccoon/utils/raccoon_parser.dart';

class RaccoonInterceptor extends InterceptorsWrapper with RaccoonAdapter {
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
                  entry.value.length,
                ),
              );
            }

            request = request.copyWith(formDataFiles: files);
          }
        } else {
          request = request.copyWith(
            size: utf8.encode(data.toString()).length,
            body: data,
          );
        }
      }

      request = request.copyWith(
        time: DateTime.now(),
        headers: RaccoonParser.parseHeaders(headers: options.headers),
        contentType: options.contentType.toString(),
        queryParameters: uri.queryParameters,
        curl: RaccoonParser.generateCurlCommand(options),
      );

      var seed = call.copyWith(
        method: options.method,
        endpoint: path,
        server: uri.host,
        client: "Dio",
        uri: options.uri.toString(),
        secure: uri.scheme == 'https',
        request: request,
      );

      service.addCall(seed);
    } catch (e) {
      print("ERROR ON REQUEST $e");
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      var httpResponse = RaccoonHttpResponse();

      if (response.data == null) {
        httpResponse = httpResponse.copyWith(
          body: "",
          size: 0,
        );
      } else {
        httpResponse = httpResponse.copyWith(
          body: response.data,
          size: utf8.encode(response.data.toString()).length,
        );
      }

      final headers = <String, String>{};

      response.headers.forEach((header, values) {
        headers[header] = values.toString();
      });

      httpResponse = httpResponse.copyWith(
        status: response.statusCode,
        time: DateTime.now(),
        headers: headers,
      );

      service.addResponse(httpResponse, response.requestOptions.hashCode);
    } catch (e) {
      print("ERROR ON RESPONSE $e");
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    var httpError = RaccoonHttpError(
      error: err.toString(),
    );

    if (err is Error) {
      final basicError = err as Error;
      httpError = httpError.copyWith(
        stackTrace: basicError.stackTrace,
      );
    }

    service.addError(httpError, err.requestOptions.hashCode);

    var httpResponse = RaccoonHttpResponse(
      time: DateTime.now(),
    );

    if (err.response == null) {
      httpResponse = httpResponse.copyWith(
        status: -1,
      );
      service.addResponse(httpResponse, err.requestOptions.hashCode);
    } else {
      httpResponse = httpResponse.copyWith(
        status: err.response?.statusCode,
      );

      if (err.response!.data == null) {
        httpResponse = httpResponse.copyWith(
          body: "",
          size: 0,
        );
      } else {
        httpResponse = httpResponse.copyWith(
          body: err.response?.data,
          size: utf8.encode(err.response!.data.toString()).length,
        );
      }

      final headers = <String, String>{};

      err.response!.headers.forEach((header, values) {
        headers[header] = values.toString();
      });

      httpResponse = httpResponse.copyWith(
        headers: headers,
      );

      service.addResponse(
        httpResponse,
        err.response!.requestOptions.hashCode,
      );
    }
    return handler.next(err);
  }
}
