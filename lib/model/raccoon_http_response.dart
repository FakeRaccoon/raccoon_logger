import 'package:equatable/equatable.dart';

class RaccoonHttpResponse with EquatableMixin {
  RaccoonHttpResponse({
    this.status = 0,
    this.size = 0,
    DateTime? time,
    this.body,
    this.headers = const <String, String>{},
  }) : time = time ?? DateTime.now();

  final int? status;
  final int size;
  final DateTime time;
  final dynamic body;
  final Map<String, String> headers;

  RaccoonHttpResponse copyWith({
    int? status,
    int? size,
    DateTime? time,
    dynamic body,
    Map<String, String>? headers,
  }) {
    return RaccoonHttpResponse(
      status: status ?? this.status,
      size: size ?? this.size,
      time: time ?? this.time,
      body: body ?? this.body,
      headers: headers ?? this.headers,
    );
  }

  @override
  List<Object?> get props => [
        status,
        size,
        time,
        body,
        headers,
      ];
}
