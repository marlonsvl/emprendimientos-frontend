import 'dart:async';
import 'package:dio/dio.dart';
import 'package:emprendegastroloja/core/errors/failures.dart';
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
  Future<void> deleteAccount();
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
              // Debug log
            } else {
              //print('No access token found!'); // Debug log
            }
          }
          handler.next(options);
        },
        // --- ADD onError LOGIC ---
        onError: (DioException error, handler) async {
          // Check if the error is 401 Unauthorized and not the login request itself
          if (error.response?.statusCode == 401 && _requiresAuth(error.requestOptions.path)) {
            // Get the refresh token
            final refreshToken = await localDataSource.getRefreshToken();

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // 1. Try to refresh the token
                final newAuthResponse = await _refreshAuthToken(refreshToken);

                // 2. Save the new tokens locally
                await localDataSource.saveAuthData(newAuthResponse);

                // 3. Update the request header with the new Access Token
                final newAccessToken = newAuthResponse.accessToken;
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                // 4. Re-send the original failed request
                // Use _tokenDio to prevent recursion in the interceptor
                final response = await dio.request(
                  error.requestOptions.path,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );

                // 5. Resolve the handler with the successful re-sent response
                return handler.resolve(response);

              } on ServerException {
                // If refresh fails (e.g., refresh token is also expired), force logout
                await localDataSource.clearAuthData();
                return handler.next(error); // Proceed to error state (AuthUnauthenticated)
              }
            } else {
              // No refresh token available, force logout
              await localDataSource.clearAuthData();
            }
          }
          
          // For all other errors (404, 500, or 401 on an unhandled path), pass it down
          return handler.next(error);
        },
      ),
    );
  }

  bool _requiresAuth(String path) {
    return path.contains('/auth/users/me/') ||
        path.contains('/users/me/') ||
        path.contains('/profile/') ||
        path.startsWith('/api/protected/') || 
        path.contains('/api/user-profile/me/');
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
          message: '¡Inicio de sesión exitoso!',
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
          throw ServerException('Credenciales inválidas');
        }
      }
      // Handle other Dio exceptions (network, timeout, etc.)
      throw ServerException('Error de red: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors
      throw ServerException('Se produjo un error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
      //print(  'RESPONSE STATUS: ${response.data}');
      if (response.statusCode == 201) {
        // Return success response without automatic login
        // User needs to verify email before being authenticated
        return AuthResponse(
          success: true,
          message:
              '¡Registro exitoso! Por favor, revise su correo electrónico para verificar su cuenta.',
          user: null, // No user data since they're not authenticated yet
          accessToken: null, // No token since they're not authenticated yet
        );
      } else {
        throw ServerException('El registro falló');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map && errors.containsKey('email')) {
          throw ServerException('El correo electrónico ya existe');
        }
        throw ServerException('Error de registro: Datos no válidos');
      }
      throw ServerException('Error de red: ${e.message}');
    } catch (e) {
      throw ServerException('Se produjo un error inesperado');
    }
  }

  Future<AuthResponse> _refreshAuthToken(String refreshToken) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshToken, // ASSUME this constant is defined
        data: {'refresh': refreshToken},
      );
      
      if (response.statusCode == 200) {
        return AuthResponse(
          success: true,
          message: 'Token refreshed!',
          user: null,
          accessToken: response.data['access'],
          refreshToken: response.data['refresh'],
        );
      } else {
        throw ServerException('Failed to refresh token: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Treat any Dio error during refresh as a failure, triggering logout
      throw ServerException('Refresh failed. Logging out. ${e.message}');
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
        throw ServerException('Error al restablecer la contraseña');
      }
    } on DioException catch (e) {
      throw ServerException('Error de red: ${e.message}');
    } catch (e) {
      throw ServerException('Se produjo un error inesperado');
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
        throw ServerFailure('No se pudo enviar el correo electrónico de restablecimiento de contraseña');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map && errors.containsKey('email')) {
          throw ServerFailure('Dirección de correo electrónico no válida');
        }
        throw ServerFailure('No se pudo enviar el correo electrónico de restablecimiento: Datos no válidos');
      } else if (e.response?.statusCode == 404) {
        throw ServerFailure('Dirección de correo electrónico no encontrada');
      }
      throw ServerFailure('Error de red: ${e.message}');
    } catch (e) {
      throw ServerFailure('Se produjo un error inesperado');
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
        throw ServerException('Error en la actualización de contraseña');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map) {
          if (errors.containsKey('current_password')) {
            throw ServerException('La contraseña actual es incorrecta');
          } else if (errors.containsKey('new_password')) {
            throw ServerException('La nueva contraseña no cumple los requisitos');
          }
          throw ServerException('Error en la actualización de contraseña: Datos no válidos');
        }
        throw ServerException('Error en la actualización de contraseña');
      } else if (e.response?.statusCode == 401) {
        throw ServerException('Se requiere autenticación');
      }
      throw ServerException('Error de red: ${e.message}');
    } catch (e) {
      throw ServerException('Se produjo un error inesperado');
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
        throw ServerException('No se pudo enviar el correo electrónico de verificación');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data;
        if (errors is Map) {
          if (errors.containsKey('detail')) {
            final detail = errors['detail'].toString();
            if (detail.contains('already activated') ||
                detail.contains('already verified')) {
              throw ServerException('El correo electrónico ya está verificado');
            }
            throw ServerException('Error en la verificación del correo electrónico: $detail');
          }
          throw ServerException('Error en la verificación de correo electrónico: Solicitud no válida');
        }
        throw ServerException('Error en la verificación del correo electrónico');
      } else if (e.response?.statusCode == 401) {
        throw ServerException('Se requiere autenticación');
      } else if (e.response?.statusCode == 403) {
        throw ServerException('Permiso denegado');
      } else if (e.response?.statusCode == 429) {
        throw ServerException(
          'Demasiadas solicitudes. Espere antes de volver a solicitar.',
        );
      }
      throw ServerException('Error de red: ${e.message}');
    } catch (e) {
      throw ServerException('Se produjo un error inesperado');
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
        throw ServerException('No se pudieron obtener los datos del usuario');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ServerException('No autorizado: el token puede estar vencido');
      }
      throw ServerException('Erro de red: ${e.message}');
    } catch (e) {
      throw ServerException('Se produjo un error inesperado ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await dio.delete('${ApiConstants.baseUrl}/api/user-profile/me/');
      
      if (response.statusCode != 204) {
        // Use a default message if status is not 204
        throw ServerException('No se pudo eliminar la cuenta');
      }
  } on DioException catch (e) {
    throw ServerException(
      e.response?.data['error']?.toString() ?? 'Error al eliminar cuenta',
    );
  }
  }

  
}
