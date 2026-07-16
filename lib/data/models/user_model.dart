class UserModel {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? photoProfil;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.photoProfil,
    this.roles = const [],
  });

  bool get isAdmin => roles.contains('ROLE_ADMIN');

  factory UserModel.fromJson(Map<String, dynamic> json, {List<String> roles = const []}) {
    return UserModel(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      photoProfil: json['photoProfil'],
      roles: roles,
    );
  }
}