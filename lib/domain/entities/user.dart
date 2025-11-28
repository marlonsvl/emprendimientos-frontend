class User {
  final int id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.phone,
  });

  String get fullName => '$firstName $lastName';
}