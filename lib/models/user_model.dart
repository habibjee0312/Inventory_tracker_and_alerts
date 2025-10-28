class UserModel {
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? accessToken;
  final String? refreshToken;

  UserModel({
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.accessToken,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      accessToken: json['access'],
      refreshToken: json['refresh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (accessToken != null) 'access': accessToken,
      if (refreshToken != null) 'refresh': refreshToken,
    };
  }
}