class User {
  final String userId;
  final String username;
  final String role;
  final UserEntity? entity;
  final String token;

  User({
    required this.userId,
    required this.username,
    required this.role,
    this.entity,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    
    return User(
      userId: userData['user_id'] ?? '',
      username: userData['username'] ?? '',
      role: userData['role'] ?? '',
      entity: userData['entity'] != null 
          ? UserEntity.fromJson(userData['entity'])
          : null,
      token: json['token'] ?? '',
    );
  }
}

class UserEntity {
  final int id;
  final String userId;
  final String? first_name;
  final String? last_name;
  final String? phone;
  final String? address;

  UserEntity({
    required this.id,
    required this.userId,
    this.first_name,
    this.last_name,
    this.phone,
    this.address,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      first_name: json['first_name'],
      last_name: json['last_name'],
      phone: json['phone'],
      address: json['address'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': first_name,
      'last_name': last_name,
      'phone': phone,
      'address': address,
    };
  }
  
  String get fullName {
    if (first_name != null && last_name != null) {
      return '$first_name $last_name';
    } else if (first_name != null) {
      return first_name!;
    } else if (last_name != null) {
      return last_name!;
    }
    return '';
  }
}