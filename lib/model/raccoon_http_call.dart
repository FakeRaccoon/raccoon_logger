import 'package:equatable/equatable.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';

/// A single captured HTTP call: timing, endpoint, and its request, response
/// and error (any of which may be null until that stage completes).
class RaccoonHttpCall with EquatableMixin {
  RaccoonHttpCall({
    required this.id,
    this.request,
    this.response,
    this.error,
    DateTime? createdTime,
    this.method = '',
    this.endpoint = '',
    this.server = '',
    this.uri = '',
    this.duration = 0,
  }) : createdTime = createdTime ?? DateTime.now();

  final int id;
  final DateTime createdTime;
  final String method;
  final String endpoint;
  final String server;
  final String uri;
  final int duration;

  final RaccoonHttpRequest? request;
  final RaccoonHttpResponse? response;
  final RaccoonHttpError? error;

  RaccoonHttpCall copyWith({
    int? id,
    DateTime? createdTime,
    String? method,
    String? endpoint,
    String? server,
    String? uri,
    int? duration,
    RaccoonHttpRequest? request,
    RaccoonHttpResponse? response,
    RaccoonHttpError? error,
  }) {
    return RaccoonHttpCall(
      id: id ?? this.id,
      createdTime: createdTime ?? this.createdTime,
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      server: server ?? this.server,
      uri: uri ?? this.uri,
      duration: duration ?? this.duration,
      request: request ?? this.request,
      response: response ?? this.response,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdTime,
    method,
    endpoint,
    server,
    uri,
    duration,
    request,
    response,
    error,
  ];
}
