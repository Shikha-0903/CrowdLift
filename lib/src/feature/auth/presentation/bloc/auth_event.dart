import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, password, phone, role];
}

class SendPasswordResetEmailRequested extends AuthEvent {
  final String email;

  const SendPasswordResetEmailRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class CheckPhoneNumberExistsRequested extends AuthEvent {
  final String phoneNumber;

  const CheckPhoneNumberExistsRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class AuthStateChanged extends AuthEvent {
  const AuthStateChanged();
}
