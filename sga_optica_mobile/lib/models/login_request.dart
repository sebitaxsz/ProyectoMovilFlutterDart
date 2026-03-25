class LoginRequest {
  final String user_user;
  final String user_password;

  LoginRequest({
    required this.user_user,
    required this.user_password,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_user': user_user,
      'user_password': user_password,
    };
  }
}