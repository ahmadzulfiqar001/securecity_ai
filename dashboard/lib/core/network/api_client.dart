import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// These Dio instances talk only to the Python microservices (cv_engine,
// ai_engine) — never Firestore. Ported from
// mobile/lib/core/network/api_client.dart's proven pattern (auth
// interceptor, error mapping), trimmed to what the dashboard's simpler
// Result<T> (core/errors/result.dart) needs — no typed Failure hierarchy,
// just success/error-with-message.
// ─────────────────────────────────────────────────────────────────────────────

Dio createCvEngineDio() => _createDio(AppConstants.cvEngineHttpBaseUrl);

Dio createAiEngineDio() => _createDio(AppConstants.aiEngineHttpBaseUrl);

Dio _createDio(String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.apiConnectTimeout,
      receiveTimeout: AppConstants.apiReceiveTimeout,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
        'X-Client-Platform': 'dashboard',
      },
    ),
  );

  dio.interceptors.add(_AuthInterceptor());
  return dio;
}

/// Attaches the current Firebase ID token to every request — the Firebase
/// Auth SDK caches and auto-refreshes it internally, so no manual
/// refresh-token bookkeeping is needed here.
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
}

/// Turns a DioException into the short, user-facing message string
/// dashboard repositories return via `Error(message)`. [serviceName] is
/// the human-readable microservice name for the message (e.g. "Computer
/// Vision service", "AI Engine").
String describeDioError(DioException e, {String serviceName = 'backend service'}) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return 'The $serviceName timed out. Please try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the $serviceName. Is it running?';
    case DioExceptionType.badResponse:
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['detail']
          : null;
      return detail?.toString() ?? '$serviceName error (${e.response?.statusCode}).';
    default:
      return e.message ?? 'An unexpected error occurred talking to the $serviceName.';
  }
}
