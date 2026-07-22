import 'package:equatable/equatable.dart';

/// Base sealed class for all application failures.
/// Uses a sealed hierarchy so every error case is exhaustive in switch expressions.
sealed class Failure extends Equatable {
  final String message;
  final String? code;
  final Object? cause;

  const Failure({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  List<Object?> get props => [message, code, cause];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Network Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when there is no internet connection or the device is offline.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_UNAVAILABLE',
    super.cause,
  });
}

/// Thrown when a network request times out.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
    super.code = 'REQUEST_TIMEOUT',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Authentication Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when credentials are invalid or auth state is broken.
final class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please sign in again.',
    super.code,
    super.cause,
  });
}

/// Thrown when a user is not found in the system.
final class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({
    super.message = 'User account not found.',
    super.code = 'USER_NOT_FOUND',
    super.cause,
  });
}

/// Thrown when the provided email is already registered.
final class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure({
    super.message = 'An account with this email already exists.',
    super.code = 'EMAIL_ALREADY_IN_USE',
    super.cause,
  });
}

/// Thrown when an auth token is expired or revoked.
final class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure({
    super.message = 'Your session has expired. Please sign in again.',
    super.code = 'TOKEN_EXPIRED',
    super.cause,
  });
}

/// Thrown when email/password combination is incorrect.
final class WrongCredentialsFailure extends Failure {
  const WrongCredentialsFailure({
    super.message = 'Incorrect email or password.',
    super.code = 'WRONG_CREDENTIALS',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Server / API Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when the backend returns an unexpected error (5xx).
final class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    super.message = 'Server error. Please try again later.',
    super.code = 'SERVER_ERROR',
    super.cause,
    this.statusCode,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Thrown when the server returns a 400-level client error.
final class ClientFailure extends Failure {
  final int? statusCode;

  const ClientFailure({
    required super.message,
    super.code = 'CLIENT_ERROR',
    super.cause,
    this.statusCode,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Thrown when a request returns 404.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Cache / Local Storage Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when reading or writing to local cache fails.
final class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to read or write local data.',
    super.code = 'CACHE_ERROR',
    super.cause,
  });
}

/// Thrown when cached data is stale or unavailable.
final class CacheMissFailure extends Failure {
  const CacheMissFailure({
    super.message = 'No cached data available.',
    super.code = 'CACHE_MISS',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when location permission is denied by the user.
final class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure({
    super.message = 'Location permission is required. Please allow access in settings.',
    super.code = 'LOCATION_PERMISSION_DENIED',
    super.cause,
  });
}

/// Thrown when location services are disabled on the device.
final class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure({
    super.message = 'Location services are disabled. Please enable them.',
    super.code = 'LOCATION_SERVICE_DISABLED',
    super.cause,
  });
}

/// Thrown when the device cannot determine the current position.
final class LocationFailure extends Failure {
  const LocationFailure({
    super.message = 'Unable to determine your current location.',
    super.code = 'LOCATION_ERROR',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Media / Storage Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a media file exceeds the allowed size.
final class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure({
    super.message = 'File size exceeds the maximum allowed limit.',
    super.code = 'FILE_TOO_LARGE',
    super.cause,
  });
}

/// Thrown when file upload to Firebase Storage fails.
final class UploadFailure extends Failure {
  const UploadFailure({
    super.message = 'File upload failed. Please try again.',
    super.code = 'UPLOAD_ERROR',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a required system permission is not granted.
final class PermissionFailure extends Failure {
  final String permission;

  const PermissionFailure({
    required this.permission,
    super.message = 'Required permission not granted.',
    super.code = 'PERMISSION_DENIED',
    super.cause,
  });

  @override
  List<Object?> get props => [...super.props, permission];
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic / Unknown
// ─────────────────────────────────────────────────────────────────────────────

/// Catch-all for unexpected failures.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred.',
    super.code = 'UNKNOWN',
    super.cause,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Result type - lightweight Either-like wrapper without external dependency
// ─────────────────────────────────────────────────────────────────────────────

/// A discriminated union result type: either [Success] with a value of type [T],
/// or [Error] with a [Failure].
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T get valueOrThrow => switch (this) {
        Success<T>(value: final v) => v,
        Error<T>(failure: final f) =>
          throw StateError('Result is an error: ${f.message}'),
      };

  Failure get failureOrThrow => switch (this) {
        Error<T>(failure: final f) => f,
        Success<T>() => throw StateError('Result is a success, not an error.'),
      };

  /// Maps the success value to a new type [R].
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(value: final v) => Success(transform(v)),
        Error<T>(failure: final f) => Error(f),
      };

  /// Flat-maps the success value to a new [Result<R>].
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Success<T>(value: final v) => transform(v),
        Error<T>(failure: final f) => Error(f),
      };

  /// Executes [onSuccess] or [onError] depending on the result.
  void fold({
    required void Function(T value) onSuccess,
    required void Function(Failure failure) onError,
  }) {
    switch (this) {
      case Success<T>(value: final v):
        onSuccess(v);
      case Error<T>(failure: final f):
        onError(f);
    }
  }

  /// Returns value if success, otherwise returns [fallback].
  T getOrElse(T fallback) => switch (this) {
        Success<T>(value: final v) => v,
        Error<T>() => fallback,
      };
}

/// The successful variant of [Result].
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// The failure variant of [Result].
final class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

/// Convenience factory methods.
extension ResultX on Never {
  static Result<T> success<T>(T value) => Success(value);
  static Result<T> error<T>(Failure failure) => Error(failure);
}
