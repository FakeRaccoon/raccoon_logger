import 'package:equatable/equatable.dart';

/// Definition of http error data holder.
class RaccoonHttpError with EquatableMixin {
  RaccoonHttpError({
    this.error,
    this.stackTrace,
  });

  final dynamic error;
  final StackTrace? stackTrace;

  RaccoonHttpError copyWith({
    dynamic error,
    StackTrace? stackTrace,
  }) {
    return RaccoonHttpError(
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  List<Object?> get props => [error, stackTrace];
}
