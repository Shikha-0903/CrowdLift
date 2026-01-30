import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserEntity> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<bool> checkPhoneNumberExists(String phoneNumber);

  Future<void> signOut();

  UserEntity? getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('User credential is null');
      }

      return await _getUserFromFirestore(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserEntity> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('User credential is null');
      }

      final userEntity = UserEntity(
        uid: userCredential.user!.uid,
        name: name,
        email: email.trim(),
        phone: phone,
        role: role,
        description: 'Not mentioned',
        capacityAbout: 'Not mentioned',
        interestExpect: 'Not mentioned',
        profileImage: 'Note mentioned',
        aim: 'Not mentioned',
      );

      await firestore
          .collection('crowd_user')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'role': role,
        'uid': userCredential.user!.uid,
        'description': 'Not mentioned',
        'capacity_about': 'Not mentioned',
        'interest_expect': 'Not mentioned',
        'profile_image': 'Note mentioned',
        'aim': 'Not mentioned'
      }, SetOptions(merge: true));

      return userEntity;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      final querySnapshot = await firestore
          .collection('crowd_user')
          .where('phone', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking phone number: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  @override
  UserEntity? getCurrentUser() {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    // Note: This is a synchronous method, but getting from Firestore is async
    // In a real app, you might want to cache this or make it async
    return null; // Will be handled by authStateChanges stream
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirestore(firebaseUser.uid);
    });
  }

  Future<UserEntity> _getUserFromFirestore(String uid) async {
    try {
      final docSnapshot =
          await firestore.collection('crowd_user').doc(uid).get();

      if (!docSnapshot.exists) {
        throw Exception('User document not found');
      }

      final data = docSnapshot.data()!;
      return UserEntity(
        uid: data['uid'] ?? uid,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        role: data['role'] ?? '',
        description: data['description'],
        capacityAbout: data['capacity_about'],
        interestExpect: data['interest_expect'],
        profileImage: data['profile_image'],
        aim: data['aim'],
      );
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found for that email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many login attempts. Try again later.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password login is disabled.';
        break;
      case 'invalid-credential':
        message = 'The email is not registered or the password is incorrect.';
        break;
      case 'email-already-in-use':
        message =
            'This email is already registered. Please use another email or login.';
        break;
      case 'weak-password':
        message =
            'The password provided is too weak. Please use a stronger password.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred';
    }

    return Exception(message);
  }
}
