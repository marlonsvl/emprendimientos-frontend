import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  @JsonKey(name: 're_password')
  final String rePassword;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String username;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.rePassword,
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'access')
  final String? accessToken;
  @JsonKey(name: 'refresh')
  final String? refreshToken;
  final UserModel? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.firstName,
    super.lastName,
    super.profilePicture,
    super.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() => User(
    id: id,
    email: email,
    username: username,
    firstName: firstName,
    lastName: lastName,
    profilePicture: profilePicture,
    phone: phone,
  );
}

@JsonSerializable()
class PasswordResetRequest {
  final String email;

  PasswordResetRequest({required this.email});

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PasswordResetRequestToJson(this);
}