import 'package:dio/dio.dart';

/// Custom API Exception for GitHabit network requests.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Global Dio client configuration with timeouts and logging.
class DioClient {
  late final Dio dio;

  DioClient({BaseOptions? options}) {
    dio = Dio(
      options ??
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log or append authorization headers if present
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }
}

