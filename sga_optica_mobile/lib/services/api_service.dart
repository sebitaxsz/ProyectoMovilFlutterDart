// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = Constants.baseUrl;
  
  // SOLO estas rutas son públicas (NO requieren token)
  final List<String> _publicRoutes = [
    '/auth/login',
    '/auth/register',
    '/password/request-reset',
    '/password/verify-code',
    '/password/reset',
  ];

  // Método para verificar si una ruta es pública
  bool _isPublicRoute(String endpoint) {
    return _publicRoutes.any((route) => endpoint.contains(route));
  }

  // Método para obtener headers (con o sin token según la ruta)
  Future<Map<String, String>> _getHeaders(String endpoint, {String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // SOLO agregar token si:
    // 1. La ruta NO es pública
    // 2. Hay token disponible
    // 3. El token no está vacío
    if (!_isPublicRoute(endpoint) && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // ─── LOGIN (público) ──────────────────────────────────────────────────────
  Future<User> login(String username, String password) async {
    try {
      final endpoint = Constants.loginEndpoint;
      final headers = await _getHeaders(endpoint);
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode({'user_user': username, 'user_password': password}),
      );

      print('=== LOGIN ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['token'] != null && data['user'] != null) {
          return User.fromJson(data);
        }
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

  // ─── REGISTER (público) ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> request) async {
    try {
      final endpoint = Constants.registerEndpoint;
      final headers = await _getHeaders(endpoint);
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(request),
      );

      print('=== REGISTER === Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Error en el registro');
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  // ─── SOLICITAR RECUPERACIÓN DE CONTRASEÑA (público) ───────────────────────
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final endpoint = Constants.requestResetEndpoint;
    final headers = await _getHeaders(endpoint);  // No enviará token
    
    print('=== REQUEST PASSWORD RESET ===');
    print('URL: $baseUrl$endpoint');
    print('Headers: $headers');
    
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode({'correo': email}),
        )
        .timeout(Constants.connectionTimeout);
        
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
        
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(error['message'] ?? 'Error al solicitar el código');
  }

  // ─── VERIFICAR CÓDIGO (público) ──────────────────────────────────────────
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    final endpoint = Constants.verifyCodeEndpoint;
    final headers = await _getHeaders(endpoint);  // No enviará token
    
    print('=== VERIFY RESET CODE ===');
    print('URL: $baseUrl$endpoint');
    
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode({'correo': email, 'code': code}),
        )
        .timeout(Constants.connectionTimeout);
        
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
        
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(error['message'] ?? 'Código incorrecto');
  }

  // ─── RESTABLECER CONTRASEÑA (público) ─────────────────────────────────────
  Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword, String confirmPassword) async {
    final endpoint = Constants.resetPasswordEndpoint;
    final headers = await _getHeaders(endpoint);  // No enviará token
    
    print('=== RESET PASSWORD ===');
    print('URL: $baseUrl$endpoint');
    
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode({
            'correo': email,
            'code': code,
            'nueva_contrasena': newPassword,
            'confirmar_contrasena': confirmPassword,
          }),
        )
        .timeout(Constants.connectionTimeout);
        
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
        
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final error = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(error['message'] ?? 'Error al restablecer la contraseña');
  }

  // ─── PRODUCTOS (requieren token) ──────────────────────────────────────────
  Future<ProductsPaginatedResponse> getProducts({int page = 1, String? token}) async {
    final endpoint = Constants.productsEndpoint;
    final headers = await _getHeaders(endpoint, token: token);
    
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint?page=$page'),
          headers: headers,
        )
        .timeout(Constants.connectionTimeout);
        
    if (response.statusCode == 200) {
      return ProductsPaginatedResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cargar productos: ${response.statusCode}');
  }

  Future<Product> getProductById(int id, {String? token}) async {
    final endpoint = '${Constants.productsEndpoint}/$id';
    final headers = await _getHeaders(endpoint, token: token);
    
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
        )
        .timeout(Constants.connectionTimeout);
        
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cargar producto: ${response.statusCode}');
  }

  // ─── PERFIL DEL CLIENTE (requiere token) ──────────────────────────────────
  Future<Map<String, dynamic>> updateCustomerProfile(
      String token, Map<String, dynamic> data) async {
    final endpoint = '/customer/profile';
    final headers = await _getHeaders(endpoint, token: token);  // Enviará token

    print('=== UPDATE CUSTOMER PROFILE ===');
    print('URL: $baseUrl$endpoint');
    print('Payload: $data');

    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(Constants.connectionTimeout);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Error al actualizar perfil');
    } catch (_) {
      throw Exception('Error ${response.statusCode} al actualizar perfil');
    }
  }
}