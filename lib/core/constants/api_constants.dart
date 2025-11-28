// lib/core/constants/api_constants.dart
class ApiConstants {
  // Change this to your backend's base URL
  //static const String baseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = 'https://emprendimientos-5xzh.onrender.com';

  // Auth endpoints (optional helpers, not required but nice to have)
  static const String login = '$baseUrl/auth/jwt/create/';
  static const String register = '$baseUrl/auth/users/';
  static const String resetPassword = '$baseUrl/auth/users/reset_password/';
  static const String currentUser = '$baseUrl/auth/users/me/';

  // You can add more endpoints here later:
  static const String refreshToken = '$baseUrl/auth/jwt/refresh/';
  static const String logout = '$baseUrl/auth/logout/';
}
