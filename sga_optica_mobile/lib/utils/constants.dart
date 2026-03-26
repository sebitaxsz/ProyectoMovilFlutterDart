class Constants {
  static const String baseUrl = 'https://7l77sjp2-3002.use2.devtunnels.ms/api/v1';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}