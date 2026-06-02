class ApiConstants {
  static const String baseUrl = 'http://192.168.137.1:3000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';

  // Ticket endpoints
  static const String tickets = '$baseUrl/tickets';
  static String ticketById(String id) => '$baseUrl/tickets/$id';
  static String ticketAssign(String id) => '$baseUrl/tickets/$id/assign';
  static String ticketStatus(String id) => '$baseUrl/tickets/$id/status';
  static String ticketResolve(String id) => '$baseUrl/tickets/$id/resolve';
  static String ticketHistory(String id) => '$baseUrl/tickets/$id/history';
  static String ticketComments(String id) => '$baseUrl/tickets/$id/comments';
  static String ticketAttachments(String id) => '$baseUrl/tickets/$id/attachments';
}
