// lib/presentation/bloc/auth/auth_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthRegistered extends AuthState {
  final String message;
  
  const AuthRegistered({
    this.message = 'Registration successful! Please verify your email.',
  });

  @override
  List<Object> get props => [message];
}

class PasswordResetSent extends AuthState {
  final String message;

  const PasswordResetSent({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthGuest extends AuthState {
  final User guestUser;

  const AuthGuest() : guestUser = const User(
    id: -1,
    email: 'guest@local',
    username: 'Guest',
    firstName: 'Guest',
    lastName: 'User',
    isGuest: true,
  );

  @override
  List<Object> get props => [guestUser];
}