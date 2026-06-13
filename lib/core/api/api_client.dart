import 'package:dio/dio.dart';
import 'package:occasio/core/constants/api_constants.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // You can add auth token here from secure storage
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle global errors here
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
