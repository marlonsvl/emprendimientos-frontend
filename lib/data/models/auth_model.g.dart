// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      rePassword: json['re_password'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      username:json['username'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      're_password': instance.rePassword,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'username': instance.username,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user': instance.user,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePicture: json['profilePicture'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'profilePicture': instance.profilePicture,
      'phone': instance.phone,
    };

PasswordResetRequest _$PasswordResetRequestFromJson(
        Map<String, dynamic> json) =>
    PasswordResetRequest(
      email: json['email'] as String,
    );

Map<String, dynamic> _$PasswordResetRequestToJson(
        PasswordResetRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
    };
