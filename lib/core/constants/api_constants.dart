class ApiConstants {
  static String _baseUrl = 'http://10.185.24.116:3000/api';

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    _baseUrl = '$url/api';
  }

  static String get apiUrl => _baseUrl;

  // Auth endpoints
  static String get register => '$_baseUrl/auth/register';
  static String get login => '$_baseUrl/auth/login';
  static String get me => '$_baseUrl/auth/me';
  static String get logout => '$_baseUrl/auth/logout';
  static String get helpdesks => '$_baseUrl/auth/helpdesks';
  static String get forgotPassword => '$_baseUrl/auth/forgot-password';
  static String get verifyOtp => '$_baseUrl/auth/verify-otp';
  static String get resetPassword => '$_baseUrl/auth/reset-password';

  // Ticket endpoints
  static String get tickets => '$_baseUrl/tickets';
  static String ticketById(String id) => '$_baseUrl/tickets/$id';
  static String ticketAssign(String id) => '$_baseUrl/tickets/$id/assign';
  static String ticketStatus(String id) => '$_baseUrl/tickets/$id/status';
  static String ticketResolve(String id) => '$_baseUrl/tickets/$id/resolve';
  static String ticketClose(String id) => '$_baseUrl/tickets/$id/close';
  static String get history => '$_baseUrl/tickets/history';
  static String ticketComments(String id) => '$_baseUrl/tickets/$id/comments';
  static String ticketAttachments(String id) => '$_baseUrl/tickets/$id/attachments';
}
