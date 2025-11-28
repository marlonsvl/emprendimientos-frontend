import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String rePassword;
  final String firstName;
  final String lastName;
  final String username;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.rePassword,
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  @override
  List<Object> get props => [email, password, rePassword, firstName, lastName];
}

class LogoutRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
  
  
}

class AuthStatusChecked extends AuthEvent {}

