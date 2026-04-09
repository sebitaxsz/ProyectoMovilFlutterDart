import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = Constants.baseUrl;

  Future<User> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'user_user': username, 'user_password': password}),
      );

      print('=== LOGIN ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['token'] != null && data['user'] != null) return User.fromJson(data);
        throw Exception('Formato de respuesta inválido');
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Error en el login');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.registerEndpoint}'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(request),
      );

      print('=== REGISTER === Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Error en el registro');
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl${Constants.requestResetEndpoint}'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'correo': email}),
        )
        .timeout(Constants.connectionTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(error['message'] ?? 'Error al solicitar el código');
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl${Constants.verifyCodeEndpoint}'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'correo': email, 'code': code}),
        )
        .timeout(Constants.connectionTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(error['message'] ?? 'Código incorrecto');
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword, String confirmPassword) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl${Constants.resetPasswordEndpoint}'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({
            'correo': email,
            'code': code,
            'nueva_contrasena': newPassword,
            'confirmar_contrasena': confirmPassword,
          }),
        )
        .timeout(Constants.connectionTimeout);
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(error['message'] ?? 'Error al restablecer la contraseña');
  }

  // ─── PRODUCTOS ─────────────────────────────────────────────────────────────

  Future<ProductsPaginatedResponse> getProducts({int page = 1}) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl${Constants.productsEndpoint}?page=$page'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        )
        .timeout(Constants.connectionTimeout);
    if (response.statusCode == 200) {
      return ProductsPaginatedResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cargar productos: ${response.statusCode}');
  }

  Future<Product> getProductById(int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl${Constants.productsEndpoint}/$id'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        )
        .timeout(Constants.connectionTimeout);
    if (response.statusCode == 200) return Product.fromJson(jsonDecode(response.body));
    throw Exception('Error al cargar producto: ${response.statusCode}');
  }

  // ─── PERFIL DEL CLIENTE ────────────────────────────────────────────────────
  //
  // Llama a: PUT /api/v1/customer/profile
  //
  // Esta ruta en la API tiene SOLO verifyToken — NO isAdmin ni isAdminOrEmployee.
  // El backend identifica al cliente por el user_id dentro del JWT.
  //
  // Campos aceptados por el backend:
  //   firstName, secondName, firstLastName, secondLastName,
  //   phoneNumber, email, address,
  //   currentPassword, newPassword, confirmNewPassword (opcionales)
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateCustomerProfile(
      String token, Map<String, dynamic> data) async {
    // URL que coincide EXACTAMENTE con la ruta de la API
    final url = '$baseUrl/customer/profile';

    print('=== UPDATE CUSTOMER PROFILE ===');
    print('URL: $url');
    print('Payload: $data');

    final response = await http
        .put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        )
        .timeout(Constants.connectionTimeout);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) return jsonDecode(response.body);

    // Extraer mensaje de error del servidor para mostrarlo al usuario
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Error al actualizar perfil');
    } catch (_) {
      throw Exception('Error ${response.statusCode} al actualizar perfil');
    }
  }
}
