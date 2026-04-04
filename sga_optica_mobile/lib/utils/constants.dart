class Constants {
  static const String baseUrl = 'https://7l77sjp2-3002.use2.devtunnels.ms/api/v1';
  static const String baseUrlImages = 'https://7l77sjp2-3002.use2.devtunnels.ms'; // IMAGENES GUARDADAS EN BASE DE DATOS
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String requestResetEndpoint = '/auth/password/request-reset';
  static const String verifyCodeEndpoint = '/auth/password/verify-code';
  static const String resetPasswordEndpoint = '/auth/password/reset';
  static const String productsEndpoint = '/products';  // Endpoints de productos
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}