import 'dart:async';
import 'package:dio/dio.dart';
import 'package:EmprendeGastronLoja/core/errors/failures.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/auth_model.dart';
import '../local/auth_local_datasource.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(LoginRequest request);
  Future<AuthResponse> register(RegisterRequest request);
  Future<void> resetPassword(PasswordResetRequest request);
  Future<UserModel> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String currentPassword, String newPassword);
  Future<UserModel> updateProfile(
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
  );
  Future<void> sendEmailVerification();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final AuthLocalDataSource localDataSource; // Add this dependency

  AuthRemoteDataSourceImpl({required this.dio, required this.localDataSource}) {
    // Add the interceptor here
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_requiresAuth(options.path)) {
            final accessToken = await localDataSource.getToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
              print(
                'Added Authorization header: Bearer ${accessToken.substring(0, 10)}...',
              ); // Debug log
            } else {
              print('No access token found!'); // Debug log
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  bool _requiresAuth(String path) {
    return path.contains('/auth/users/me/') ||
        path.contains('/users/me/') ||
        path.contains('/profile/') ||
        path.startsWith('/api/protected/');
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        //return AuthResponse.fromJson(response.data);
        return AuthResponse(
          success: true,
          message: 'Login successful!',
          user: null, // No user data since they're not authenticated yet
          accessToken: response.data['access'],
          refreshToken: response
              .data['refresh'], // No token since they're not authenticated yet
        );
      } else {
        throw ServerFailure();
      }
    } on DioException catch (e) {
      // The fix is here: Safely check for a response and then for the status code
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          throw ServerException('Invalid credentials');
        }
      }
      // Handle other Dio exceptions (network, timeout, etc.)
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors
      throw ServerException('Unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
      print(  'RESPONSE STATUS: ${response.data}');
      if (response.statusCode == 201) {
        // Return success response without automatic login
        // User needs to verify email before being authenticated
        return AuthResponse(
          success: true,
          message:
              'Registration successful! Please check your email to verify your account.',
          user: null, // No user data since they're not authenticated yet
          accessToken: null, // No token since they're not authenticated yet
        );
      } else {
        throw ServerException('Registration failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map && errors.containsKey('email')) {
          throw ServerException('Email already exists');
        }
        throw ServerException('Registration failed: Invalid data');
      }
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error occurred');
    }
  }

  @override
  Future<void> resetPassword(PasswordResetRequest request) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/auth/users/reset_password/',
        data: request.toJson(),
      );

      if (response.statusCode != 204) {
        throw ServerException('Password reset failed');
      }
    } on DioException catch (e) {
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error occurred');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/auth/users/reset_password/',
        data: {'email': email},
      );
      if (response.statusCode != 204) {
        throw ServerFailure('Failed to send password reset email');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map && errors.containsKey('email')) {
          throw ServerFailure('Invalid email address');
        }
        throw ServerFailure('Failed to send reset email: Invalid data');
      } else if (e.response?.statusCode == 404) {
        throw ServerFailure('Email address not found');
      }
      throw ServerFailure('Network error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unexpected error occurred');
    }
  }

  @override
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/auth/users/set_password/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 204) {
        throw ServerException('Password update failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map) {
          if (errors.containsKey('current_password')) {
            throw ServerException('Current password is incorrect');
          } else if (errors.containsKey('new_password')) {
            throw ServerException('New password does not meet requirements');
          }
          throw ServerException('Password update failed: Invalid data');
        }
        throw ServerException('Password update failed');
      } else if (e.response?.statusCode == 401) {
        throw ServerException('Authentication required');
      }
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error occurred');
    }
  }

  @override
  Future<UserModel> updateProfile(
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
  ) async {
    try {
      final Map<String, dynamic> requestData = {};
      if (firstName != null) requestData['first_name'] = firstName;
      if (lastName != null) requestData['last_name'] = lastName;
      if (photoUrl != null) requestData['photo_url'] = photoUrl;
      if (phoneNumber != null) requestData['phone_number'] = phoneNumber;

      final response = await dio.patch(
        '${ApiConstants.baseUrl}/auth/users/me/',
        data: requestData,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException('Profile update failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map) {
          if (errors.containsKey('first_name')) {
            throw ServerException('Invalid first name format');
          } else if (errors.containsKey('last_name')) {
            throw ServerException('Invalid last name format');
          } else if (errors.containsKey('phone_number')) {
            throw ServerException('Invalid phone number format');
          } else if (errors.containsKey('photo_url')) {
            throw ServerException('Invalid photo URL format');
          }
          throw ServerException('Profile update failed: Invalid data');
        }
        throw ServerException('Profile update failed');
      } else if (e.response?.statusCode == 401) {
        throw ServerException('Authentication required');
      } else if (e.response?.statusCode == 403) {
        throw ServerException('Permission denied');
      }
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error occurred');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/auth/users/activation/',
        data: {},
      );

      if (response.statusCode != 204) {
        throw ServerException('Failed to send email verification');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map) {
          if (errors.containsKey('detail')) {
            final detail = errors['detail'].toString();
            if (detail.contains('already activated') ||
                detail.contains('already verified')) {
              throw ServerException('Email is already verified');
            }
            throw ServerException('Email verification failed: $detail');
          }
          throw ServerException('Email verification failed: Invalid request');
        }
        throw ServerException('Email verification failed');
      } else if (e.response?.statusCode == 401) {
        throw ServerException('Authentication required');
      } else if (e.response?.statusCode == 403) {
        throw ServerException('Permission denied');
      } else if (e.response?.statusCode == 429) {
        throw ServerException(
          'Too many requests. Please wait before requesting again',
        );
      }
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error occurred');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    // This will now automatically include the Authorization header
    try {
      final response = await dio.get(ApiConstants.currentUser);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to get user data');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ServerException('Unauthorized - token may be expired');
      }
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error occurred ${e.toString()}');
    }
  }
}
