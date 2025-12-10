import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();

  String get message;
  
  @override
  List<Object> get props => [];
}

// General failures
class ServerFailure extends Failure {
  @override
  final String message;
  
  const ServerFailure([this.message = 'Server error occurred']);
  
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  @override
  final String message;
  
  const NetworkFailure([this.message = 'Network connection failed']);
  
  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  @override
  final String message;
  
  const CacheFailure([this.message = 'Cache error occurred']);
  
  @override
  List<Object> get props => [message];
}

class UnknownFailure extends Failure {
  @override
  final String message;
  
  const UnknownFailure({this.message = 'An unknown error occurred'});
  
  @override
  List<Object> get props => [message];
}


class AuthFailure extends Failure {
  @override
  final String message;
  
  const AuthFailure({required this.message});
  
  @override
  List<Object> get props => [message];
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() 
      : super(message: 'Invalid email or password');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() 
      : super(message: 'User not found');
}

class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure() 
      : super(message: 'An account with this email already exists');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() 
      : super(message: 'Password is too weak');
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() 
      : super(message: 'Invalid email address');
}

class EmailNotVerifiedFailure extends AuthFailure {
  const EmailNotVerifiedFailure() 
      : super(message: 'Please verify your email address');
}

class AccountDisabledFailure extends AuthFailure {
  const AccountDisabledFailure() 
      : super(message: 'This account has been disabled');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure() 
      : super(message: 'Too many requests. Please try again later');
}

class PasswordMismatchFailure extends AuthFailure {
  const PasswordMismatchFailure() 
      : super(message: 'Passwords do not match');
}

class TokenExpiredFailure extends AuthFailure {
  const TokenExpiredFailure() 
      : super(message: 'Session expired. Please login again');
}

class InvalidTokenFailure extends AuthFailure {
  const InvalidTokenFailure() 
      : super(message: 'Invalid authentication token');
}

class PasswordResetFailure extends AuthFailure {
  const PasswordResetFailure({String? message}) 
      : super(message: message ?? 'Failed to send password reset email');
}

class EmailUpdateFailure extends AuthFailure {
  const EmailUpdateFailure({String? message}) 
      : super(message: message ?? 'Failed to update email address');
}

class ProfileUpdateFailure extends AuthFailure {
  const ProfileUpdateFailure({String? message}) 
      : super(message: message ?? 'Failed to update profile');
}

// Validation failures
class ValidationFailure extends Failure {
  @override
  final String message;
  final Map<String, String>? fieldErrors;
  
  const ValidationFailure({
    required this.message,
    this.fieldErrors,
  });
  
  @override
  List<Object> get props => [message, fieldErrors ?? {}];
}

// Permission failures
class PermissionFailure extends Failure {
  @override
  final String message;
  
  const PermissionFailure({this.message = 'Permission denied'});
  
  @override
  List<Object> get props => [message];
}

// File/Storage failures
class StorageFailure extends Failure {
  @override
  final String message;
  
  const StorageFailure({this.message = 'Storage operation failed'});
  
  @override
  List<Object> get props => [message];
}

// Timeout failures
class TimeoutFailure extends Failure {
  @override
  final String message;
  
  const TimeoutFailure({this.message = 'Operation timed out'});
  
  @override
  List<Object> get props => [message];
}

// Platform-specific failures
class PlatformFailure extends Failure {
  @override
  final String message;
  
  const PlatformFailure({required this.message});
  
  @override
  List<Object> get props => [message];
}

// Biometric failures
class BiometricFailure extends AuthFailure {
  const BiometricFailure({super.message = 'Biometric authentication failed'});
}

class BiometricNotAvailableFailure extends AuthFailure {
  const BiometricNotAvailableFailure() 
      : super(message: 'Biometric authentication not available');
}

class BiometricNotSetupFailure extends AuthFailure {
  const BiometricNotSetupFailure() 
      : super(message: 'Biometric authentication not set up');
}

// OAuth failures
class OAuthFailure extends AuthFailure {
  const OAuthFailure({super.message = 'OAuth authentication failed'});
}

class OAuthCancelledFailure extends AuthFailure {
  const OAuthCancelledFailure() 
      : super(message: 'OAuth authentication was cancelled');
}

// Helper function to map error codes to failures
Failure mapErrorCodeToFailure(String errorCode, {String? message}) {
  switch (errorCode.toLowerCase()) {
    case 'user-not-found':
      return const UserNotFoundFailure();
    case 'wrong-password':
    case 'invalid-credential':
      return const InvalidCredentialsFailure();
    case 'email-already-in-use':
      return const UserAlreadyExistsFailure();
    case 'weak-password':
      return const WeakPasswordFailure();
    case 'invalid-email':
      return const InvalidEmailFailure();
    case 'user-disabled':
      return const AccountDisabledFailure();
    case 'too-many-requests':
      return const TooManyRequestsFailure();
    case 'operation-not-allowed':
      return AuthFailure(message: message ?? 'Operation not allowed');
    case 'network-request-failed':
      return const NetworkFailure();
    case 'timeout':
      return const TimeoutFailure();
    default:
      return AuthFailure(message: message ?? 'Authentication failed');
  }
}

class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => 'CacheException: $message';
}

// Add more exceptions if needed:
class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'Network error occurred']);

  @override
  String toString() => 'NetworkException: $message';
}