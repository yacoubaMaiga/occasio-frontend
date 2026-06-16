class AuthResponse {
  final String token;
  final String type;
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  AuthResponse({
    required this.token,
    required this.type,
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      type: json['type'] ?? 'Bearer',
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}