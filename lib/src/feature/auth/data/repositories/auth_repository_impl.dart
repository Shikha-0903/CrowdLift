import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await remoteDataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserEntity> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    return await remoteDataSource.registerWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    return await remoteDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    return await remoteDataSource.checkPhoneNumberExists(phoneNumber);
  }

  @override
  Future<void> signOut() async {
    return await remoteDataSource.signOut();
  }

  @override
  UserEntity? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }
}
