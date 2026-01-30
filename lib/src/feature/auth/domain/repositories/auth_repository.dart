import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register a new user with email and password
  Future<UserEntity> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  });

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email});

  /// Check if phone number already exists
  Future<bool> checkPhoneNumberExists(String phoneNumber);

  /// Sign out current user
  Future<void> signOut();

  /// Get current user
  UserEntity? getCurrentUser();

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;
}
