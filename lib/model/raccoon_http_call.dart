import 'package:equatable/equatable.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';

class RaccoonHttpCall with EquatableMixin {
  RaccoonHttpCall({
    required this.id,
    this.request,
    this.response,
    this.error,
    DateTime? createdTime,
    this.client = '',
    this.loading = true,
    this.secure = false,
    this.method = '',
    this.endpoint = '',
    this.server = '',
    this.uri = '',
    this.duration = 0,
  }) : createdTime = createdTime ?? DateTime.now();

  final int id;
  final DateTime createdTime;
  final String client;
  final bool loading;
  final bool secure;
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
    String? client,
    bool? loading,
    bool? secure,
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
      client: client ?? this.client,
      loading: loading ?? this.loading,
      secure: secure ?? this.secure,
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
        client,
        loading,
        secure,
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
