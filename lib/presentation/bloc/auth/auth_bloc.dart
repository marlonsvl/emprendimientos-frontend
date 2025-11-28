import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/register_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';



class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.resetPasswordUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);

    // Check authentication status on initialization
    add(AuthStatusChecked());
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await loginUseCase(LoginParams(
      username: event.username,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onRegisterRequested(
  RegisterRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());
  
  final result = await registerUseCase(RegisterParams(
    email: event.email,
    password: event.password,
    rePassword: event.rePassword,
    firstName: event.firstName,
    lastName: event.lastName,
    username: event.username,
  ));
  
  result.fold(
    (failure) => emit(AuthError(message: failure.message)),
    (message) => emit(AuthRegistered(message: message)), // Changed: now emits AuthRegistered with message
  );
}

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await resetPasswordUseCase(event.email);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const PasswordResetSent(
        message: 'Password reset email sent. Check your inbox.',
      )),
    );
  }

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await authRepository.isSignedIn();
    
    if (isLoggedIn) {
      final result = await getCurrentUserUseCase();
      result.fold(
        (failure) => emit(AuthUnauthenticated()),
        (user) => user != null
            ? emit(AuthAuthenticated(user: user))
            : emit(AuthUnauthenticated()),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }
}