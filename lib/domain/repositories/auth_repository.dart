import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Register a new user with email and password
  Future<Either<Failure, String>> register({
    required String email,
    required String password,
    required String rePassword,
    required String firstName,
    required String lastName,
    required String username,
  });

  /// Sign in user with email and password
  //Future<Either<Failure, User>> signIn({
  //  required String email,
  //  required String password,
  //});

  /// Login user with email and password (alias for signIn)
  Future<Either<Failure, User>> login(String username, String password);

  /// Sign out current user
  //Future<Either<Failure, void>> signOut();

  /// Logout current user (alias for signOut)
  Future<Either<Failure, void>> logout();

  /// Get current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Check if user is currently signed in
  Future<bool> isSignedIn();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Reset password by sending email (alias for sendPasswordResetEmail)
  Future<Either<Failure, void>> resetPassword(String email);

  /// Update user password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
  });

  /// Update user email
  //Future<Either<Failure, void>> updateEmail({
  //  required String newEmail,
  //  required String password,
  //});

  /// Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  /// Verify email with token
  //Future<Either<Failure, void>> verifyEmail({
  //  required String token,
  //});

  /// Refresh authentication token
  //Future<Either<Failure, String>> refreshToken();

  /// Delete user account
  //Future<Either<Failure, void>> deleteAccount({
  //  required String password,
  //});

  /// Sign in with Google
  //Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with Apple
  //Future<Either<Failure, User>> signInWithApple();

  /// Sign in with Facebook
  //Future<Either<Failure, User>> signInWithFacebook();

  /// Sign in with biometric authentication
  //Future<Either<Failure, User>> signInWithBiometric();

  /// Enable biometric authentication for current user
  //Future<Either<Failure, void>> enableBiometric();

  /// Disable biometric authentication for current user
  //Future<Either<Failure, void>> disableBiometric();

  /// Check if biometric authentication is available
  //Future<bool> isBiometricAvailable();

  /// Check if biometric authentication is enabled for current user
  //Future<bool> isBiometricEnabled();

  /// Validate current session
  //Future<Either<Failure, bool>> validateSession();

  /// Get user authentication stream
  //Stream<User?> get authStateChanges;

  /// Get user profile stream
  //Stream<User?> get userChanges;

  /// Check if email is already registered
  //Future<Either<Failure, bool>> isEmailRegistered({
  //  required String email,
  //});

  /// Verify phone number with OTP
  //Future<Either<Failure, void>> verifyPhoneNumber({
  //  required String phoneNumber,
  //  required void Function(String verificationId) onCodeSent,
  //  required void Function(String error) onError,
  //});

  /// Confirm phone number verification with OTP code
  //Future<Either<Failure, void>> confirmPhoneVerification({
  //  required String verificationId,
  //  required String otpCode,
  //});

  /// Sign in anonymously
  //Future<Either<Failure, User>> signInAnonymously();

  /// Link anonymous account with email/password
  //Future<Either<Failure, User>> linkAnonymousWithEmail({
  //  required String email,
  //  required String password,
 // });

  /// Get cached user data
  //Future<Either<Failure, User?>> getCachedUser();

  /// Cache user data locally
  //Future<Either<Failure, void>> cacheUser(User user);

  /// Clear cached user data
  //Future<Either<Failure, void>> clearCachedUser();

  /// Reset password with token (from email link)
  //Future<Either<Failure, void>> resetPasswordWithToken({
  //  required String token,
  //  required String newPassword,
  //});

  /// Change password (requires current password)
  //Future<Either<Failure, void>> changePassword({
  //  required String currentPassword,
  //  required String newPassword,
  //});

  /// Reauthenticate user with password
  //Future<Either<Failure, void>> reauthenticate({
  //  required String password,
  //});

  /// Get authentication token
  Future<Either<Failure, String>> getAuthToken();

  /// Check password strength
  //Either<Failure, bool> checkPasswordStrength(String password);

  /// Validate email format
  //Either<Failure, bool> validateEmailFormat(String email);

  /// Check if passwords match
  //Either<Failure, bool> checkPasswordsMatch(String password, String confirmPassword);
}