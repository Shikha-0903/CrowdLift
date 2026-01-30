import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? description;
  final String? capacityAbout;
  final String? interestExpect;
  final String? profileImage;
  final String? aim;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.description,
    this.capacityAbout,
    this.interestExpect,
    this.profileImage,
    this.aim,
  });

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        phone,
        role,
        description,
        capacityAbout,
        interestExpect,
        profileImage,
        aim,
      ];
}
