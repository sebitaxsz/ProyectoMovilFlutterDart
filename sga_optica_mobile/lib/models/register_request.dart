class RegisterRequest {
  final String user_user;
  final String user_password;
  final int role_id;
  final String? first_name;
  final String? last_name;
  final String? phone;
  final String? address;

  RegisterRequest({
    required this.user_user,
    required this.user_password,
    required this.role_id,
    this.first_name,
    this.last_name,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_user': user_user,
      'user_password': user_password,
      'role_id': role_id,
      'first_name': first_name,
      'last_name': last_name,
      'phone': phone,
      'address': address,
    };
  }
}