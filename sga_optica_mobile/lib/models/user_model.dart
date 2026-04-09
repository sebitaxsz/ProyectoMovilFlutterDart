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
    final userData = json['user'] as Map<String, dynamic>;
    return User(
      userId:   userData['user_id']  ?? '',
      username: userData['username'] ?? '',
      role:     userData['role']     ?? '',
      entity:   userData['entity'] != null
          ? UserEntity.fromJson(userData['entity'] as Map<String, dynamic>)
          : null,
      token: json['token'] ?? '',
    );
  }
}

class UserEntity {
  final int id;
  final String userId;

  // Campos tabla user_entity
  final String? first_name;
  final String? last_name;
  final String? phone;
  final String? address;

  // Campos extra de tabla customer (segundo nombre y segundo apellido)
  final String? secondName;
  final String? secondLastName;

  UserEntity({
    required this.id,
    required this.userId,
    this.first_name,
    this.last_name,
    this.phone,
    this.address,
    this.secondName,
    this.secondLastName,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id:             (json['id'] as num?)?.toInt() ?? 0,
      userId:         json['user_id']       ?? '',
      first_name:     json['first_name'],
      last_name:      json['last_name'],
      phone:          json['phone'],
      address:        json['address'],
      secondName:     json['secondName'],
      secondLastName: json['secondLastName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'user_id':        userId,
    'first_name':     first_name,
    'last_name':      last_name,
    'phone':          phone,
    'address':        address,
    'secondName':     secondName,
    'secondLastName': secondLastName,
  };

  String get fullName {
    final parts = <String>[
      if (first_name != null && first_name!.isNotEmpty) first_name!,
      if (last_name  != null && last_name!.isNotEmpty)  last_name!,
    ];
    return parts.join(' ');
  }
}
