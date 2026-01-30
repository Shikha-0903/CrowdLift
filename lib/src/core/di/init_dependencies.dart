import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crowdlift/src/core/di/service_locator.dart';
import 'package:crowdlift/src/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:crowdlift/src/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:crowdlift/src/feature/auth/domain/repositories/auth_repository.dart';
import 'package:crowdlift/src/feature/auth/presentation/bloc/auth_bloc.dart';

Future<void> initDependencies() async {
  _initCore();
  _initAuth();
}

void _initCore() {
  // Core Dependencies - Firebase instances
  serviceLocator.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );

  serviceLocator.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
}

void _initAuth() {
  // Datasource
  serviceLocator.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: serviceLocator(),
      firestore: serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: serviceLocator(),
    ),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => AuthBloc(authRepository: serviceLocator()),
  );
}
