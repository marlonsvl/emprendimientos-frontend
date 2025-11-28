import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, String>> call(RegisterParams params) async {
    return await repository.register(
      email: params.email,
      password: params.password,
      rePassword: params.rePassword,
      firstName: params.firstName,
      lastName: params.lastName,
      username: params.username,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String rePassword;
  final String firstName;
  final String lastName;
  final String username;

  RegisterParams({
    required this.email,
    required this.password,
    required this.rePassword,
    required this.firstName,
    required this.lastName,
    required this.username,
  });
}
