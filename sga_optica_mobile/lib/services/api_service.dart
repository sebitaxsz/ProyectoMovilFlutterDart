import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = Constants.baseUrl;

  Future<User> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_user': username,
          'user_password': password,
        }),
      );

      print('=== LOGIN REQUEST ===');
      print('URL: $baseUrl${Constants.loginEndpoint}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['token'] != null && data['user'] != null) {
          return User.fromJson(data);
        } else {
          throw Exception('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 401) {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Usuario o contraseña incorrectos');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en el login');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request),
      );

      print('=== REGISTER REQUEST ===');
      print('URL: $baseUrl${Constants.registerEndpoint}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 409) {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'El usuario ya existe');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en el registro');
      }
    } catch (e) {
      print('Register error: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Solicitar código de recuperación
Future<Map<String, dynamic>> requestPasswordReset(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/request-reset'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'correo': email}),
    ).timeout(Constants.connectionTimeout);

    print('=== REQUEST RESET CODE ===');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al solicitar el código');
    }
  } catch (e) {
    print('Request reset error: $e');
    throw Exception('Error de conexión: $e');
  }
}

Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/verify-code'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'correo': email,
        'code': code,
      }),
    ).timeout(Constants.connectionTimeout);

    print('=== VERIFY RESET CODE ===');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Código incorrecto');
    }
  } catch (e) {
    print('Verify code error: $e');
    throw Exception('Error de conexión: $e');
  }
}

// Restablecer contraseña
Future<Map<String, dynamic>> resetPassword(
  String email, 
  String code, 
  String newPassword, 
  String confirmPassword
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/reset'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'correo': email,
        'code': code,
        'nueva_contrasena': newPassword,
        'confirmar_contrasena': confirmPassword,
      }),
    ).timeout(Constants.connectionTimeout);

    print('=== RESET PASSWORD ===');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al restablecer la contraseña');
    }
  } catch (e) {
    print('Reset password error: $e');
    throw Exception('Error de conexión: $e');
  }
}
}