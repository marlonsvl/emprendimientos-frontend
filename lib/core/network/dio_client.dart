import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  final SharedPreferences sharedPreferences;
  late final Dio dio;

  DioClient({required this.sharedPreferences}) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://127.0.0.1', // TODO: replace with your API URL
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if exists
          final token = sharedPreferences.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Handle or log responses here if needed
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Optionally do custom error handling here
          return handler.next(e);
        },
      ),
    );
  }
}
