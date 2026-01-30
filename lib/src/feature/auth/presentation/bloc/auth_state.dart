import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SignInSuccess extends AuthState {
  final UserEntity user;

  const SignInSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class RegisterSuccess extends AuthState {
  final UserEntity user;

  const RegisterSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class PasswordResetEmailSent extends AuthState {
  const PasswordResetEmailSent();
}

class PhoneNumberExists extends AuthState {
  const PhoneNumberExists();
}

class PhoneNumberAvailable extends AuthState {
  const PhoneNumberAvailable();
}
