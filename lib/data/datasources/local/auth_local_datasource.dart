import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/failures.dart';
import '../../models/auth_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> saveAuthData(AuthResponse authResponse);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<UserModel?> getCachedUser();
  Future<void> clearAuthData();
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String accessTokenKey = 'access';
  static const String refreshTokenKey = 'refresh';
  static const String userDataKey = 'user';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      if (authResponse.accessToken != null) {
        await sharedPreferences.setString(
          accessTokenKey,
          authResponse.accessToken!,
        );
      }
      
      if (authResponse.refreshToken != null) {
        await sharedPreferences.setString(
          refreshTokenKey,
          authResponse.refreshToken!,
        );
      }
      
      if (authResponse.user != null) {
        await sharedPreferences.setString(
          userDataKey,
          json.encode(authResponse.user!.toJson()),
        );
      }
    } catch (e) {
      throw CacheFailure();
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return sharedPreferences.getString(accessTokenKey);
    } catch (e) {
      throw InvalidTokenFailure();
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return sharedPreferences.getString(refreshTokenKey);
    } catch (e) {
      throw InvalidTokenFailure();
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userDataString = sharedPreferences.getString(userDataKey);
      if (userDataString != null) {
        final userJson = json.decode(userDataString);
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      throw CacheFailure();
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        sharedPreferences.remove(accessTokenKey),
        sharedPreferences.remove(refreshTokenKey),
        //sharedPreferences.remove(userDataKey),
      ]);
    } catch (e) {
      throw CacheFailure();
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = sharedPreferences.getString(accessTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}