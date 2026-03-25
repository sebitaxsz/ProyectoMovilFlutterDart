class Constants {
  static const String baseUrl = 'http://localhost:3002/api/v1';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/user/register';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}