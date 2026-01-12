class User {
  final int id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String? phone;
  final bool isGuest;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.phone,
    this.isGuest = false,
  });

  String get fullName => '$firstName $lastName';
  factory User.guest() {
    return User(
      id: -1,
      email: 'guest@local',
      username: 'Guest',
      firstName: 'Guest',
      lastName: 'User',
      isGuest: true,
    );
  }
}