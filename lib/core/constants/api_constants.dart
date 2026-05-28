class ApiConstants {
  static const String baseUrl = 'http://192.168.49.116:3000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';
}
