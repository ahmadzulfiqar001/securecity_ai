import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';

part 'api_client.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
//
// This Dio instance talks only to the ai_engine / cv_engine microservices
// (crime prediction, safety scoring, CV detection) — the ones Firebase can't
// host. Core app data (auth, users, incidents, SOS, notifications) goes
// straight from the client to Firebase and never touches this client.
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Dio dio(Ref ref) {
  return ApiClientFactory.create();
}

@riverpod
ApiClient apiClient(Ref ref) {
  final dioInstance = ref.watch(dioProvider);
  return ApiClient(dioInstance);
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory — assembles Dio with interceptors
// ─────────────────────────────────────────────────────────────────────────────

abstract final class ApiClientFactory {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiConnectTimeout,
        receiveTimeout: AppConstants.apiReceiveTimeout,
        sendTimeout: AppConstants.apiSendTimeout,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
          'X-Client-Platform': 'mobile',
          'X-Client-Version': '1.0.0',
        },
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(dio: dio, maxRetries: AppConstants.apiMaxRetries),
      _ErrorInterceptor(),
      _LoggingInterceptor(),
    ]);

    return dio;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiClient — typed request helpers
// ─────────────────────────────────────────────────────────────────────────────

class ApiClient {
  final Dio _dio;

  const ApiClient(this._dio);

  /// GET request — returns decoded data or throws [Failure].
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST request.
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// PUT request.
  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// PATCH request.
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE request.
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Multipart upload with progress tracking.
  Future<T> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  T _extractData<T>(Response<T> response) {
    if (response.data == null) {
      throw const ServerFailure(message: 'Empty response from server.');
    }
    return response.data!;
  }

  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutFailure(cause: e);

      case DioExceptionType.connectionError:
        return NetworkFailure(cause: e);

      case DioExceptionType.cancel:
        return const ClientFailure(
          message: 'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        final serverMessage = _extractErrorMessage(responseData);

        if (statusCode == 401) {
          return TokenExpiredFailure(cause: e);
        } else if (statusCode == 403) {
          return AuthFailure(message: serverMessage ?? 'Access forbidden.', cause: e);
        } else if (statusCode == 404) {
          return NotFoundFailure(cause: e);
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ClientFailure(
            message: serverMessage ?? 'Client error occurred.',
            statusCode: statusCode,
            cause: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            message: serverMessage ?? 'Server error. Please try again later.',
            statusCode: statusCode,
            cause: e,
          );
        }
        return UnknownFailure(cause: e);

      default:
        return UnknownFailure(
          message: e.message ?? 'An unexpected error occurred.',
          cause: e,
        );
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String?;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Interceptor — attaches the current Firebase ID token to every request.
//
// The Firebase Auth SDK caches and auto-refreshes ID tokens internally, so
// there is no manual refresh-token bookkeeping here: getIdToken() returns a
// cached token when it's still valid and transparently refreshes it when
// it's about to expire.
// ─────────────────────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Force-refresh the ID token once and retry the original request.
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          handler.next(err);
          return;
        }

        final newToken = await user.getIdToken(true);
        if (newToken == null) {
          handler.next(err);
          return;
        }

        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await Dio().fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — propagate original error
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Retry Interceptor — exponential backoff for transient errors
// ─────────────────────────────────────────────────────────────────────────────

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  _RetryInterceptor({required this.dio, required this.maxRetries});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retriesLeft = err.requestOptions.extra['retries'] as int? ?? maxRetries;

    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);

    if (retriesLeft > 0 && isRetryable) {
      final delay = AppConstants.apiRetryDelay * (maxRetries - retriesLeft + 1);
      await Future<void>.delayed(delay);

      err.requestOptions.extra['retries'] = retriesLeft - 1;
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Interceptor — normalizes error responses
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Normalize error messages from server
    if (err.response?.data is Map<String, dynamic>) {
      final data = err.response!.data as Map<String, dynamic>;
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message != null) {
        // Attach normalized message to extra for downstream consumption
        err.requestOptions.extra['serverMessage'] = message.toString();
      }
    }
    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logging Interceptor — structured request/response logging
// ─────────────────────────────────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] --> ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] <-- ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print(
        '[API] ✗ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri} — ${err.message}',
      );
      return true;
    }());
    handler.next(err);
  }
}
