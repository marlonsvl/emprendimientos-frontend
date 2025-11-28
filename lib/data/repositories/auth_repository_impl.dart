import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/auth_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
Future<Either<Failure, User>> login(String username, String password) async {
  if (await networkInfo.isConnected) {
    try {
      final request = LoginRequest(username: username, password: password);
      final result = await remoteDataSource.login(request);

      // Save auth data locally FIRST
      await localDataSource.saveAuthData(result);

      // Now get complete user data (this will use the saved token)
      final user = await remoteDataSource.getCurrentUser();
      return Right(user.toEntity());
    } on ServerException catch (e) {
      if (e.message.contains('Unauthorized')) {
        // Clear any stored auth data if unauthorized
        await localDataSource.clearAuthData();
      }
      return Left(ServerFailure(e.message));
    }
  } else {
    return Left(NetworkFailure());
  }
}

  @override
Future<Either<Failure, String>> register({
  required String email,
  required String password,
  required String rePassword,
  required String firstName,
  required String lastName,
  required String username,
}) async {
  if (await networkInfo.isConnected) {
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        rePassword: rePassword,
        firstName: firstName,
        lastName: lastName,
        username: username,
      );
      
      // Register user but don't save auth data or get current user
      await remoteDataSource.register(request);
      
      // Return success message instead of User
      return const Right('Registration successful! Please check your email to verify your account.');
      
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  } else {
    return Left(NetworkFailure('No internet connection'));
  }
}

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearAuthData();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    if (await networkInfo.isConnected) {
      try {
        final request = PasswordResetRequest(email: email);
        await remoteDataSource.resetPassword(request);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return  Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      
      if (await networkInfo.isConnected) {
        final user = await remoteDataSource.getCurrentUser();
        return Right(user.toEntity());
      }
      
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendPasswordResetEmail(email);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }
  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePassword(
          currentPassword,
          newPassword,
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.updateProfile(
          firstName,
          lastName,
          photoUrl,
          phoneNumber,
        );
        await localDataSource.getCachedUser();
        return Right(user);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }
  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendEmailVerification();
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> getAuthToken() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        return Right(token);
      } else {
        return Left(AuthFailure(message: 'No auth token found'));
      }
    } catch (e) {
      return Left(CacheFailure());
    }
  }

   @override
  Future<bool> isSignedIn() async {
    try {
      final user = await getCurrentUser();
      return user.fold(
        (failure) => false,
        (user) => user != null,
      );
    } catch (e) {
      return false;
    }
  }
  
}
