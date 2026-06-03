import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ticket_model.dart';
import '../../domain/entities/ticket_enum.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getTickets(String token);
  Future<TicketModel> getTicketById(String token, String id);
  Future<TicketModel> createTicket(String token, {
    required String title,
    required String description,
    required TicketPriority priority,
  });
  Future<TicketModel> assignTicket(String token, String ticketId, String assignedTo);
  Future<TicketModel> updateTicketStatus(String token, String ticketId, String status);
  Future<TicketModel> resolveTicket(String token, String ticketId);
  Future<TicketModel> closeTicket(String token, String ticketId);
  Future<List<Map<String, dynamic>>> getAllHistory(String token);
  Future<List<Map<String, dynamic>>> getComments(String token, String ticketId);
  Future<Map<String, dynamic>> addComment(String token, String ticketId, String content, {String? parentCommentId});
  Future<void> deleteComment(String token, String ticketId, String commentId);
  Future<Map<String, dynamic>> uploadAttachment(String token, String ticketId, List<int> fileBytes, String filename);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final http.Client client;

  TicketRemoteDataSourceImpl({required this.client});

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  @override
  Future<List<TicketModel>> getTickets(String token) async {
    final response = await client.get(
      Uri.parse(ApiConstants.tickets),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      final List<dynamic> data = body['data'];
      return data.map((json) => _parseTicket(json)).toList();
    }
    throw Exception(body['message'] ?? 'Failed to fetch tickets');
  }

  @override
  Future<TicketModel> getTicketById(String token, String id) async {
    final response = await client.get(
      Uri.parse(ApiConstants.ticketById(id)),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return _parseTicket(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch ticket');
  }

  @override
  Future<TicketModel> createTicket(String token, {
    required String title,
    required String description,
    required TicketPriority priority,
  }) async {
    final response = await client.post(
      Uri.parse(ApiConstants.tickets),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority.label,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body['success'] == true) {
      return _parseTicket(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create ticket');
  }

  @override
  Future<TicketModel> assignTicket(String token, String ticketId, String assignedTo) async {
    final response = await client.post(
      Uri.parse(ApiConstants.ticketAssign(ticketId)),
      headers: _headers(token),
      body: jsonEncode({'assignedTo': assignedTo}),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return _parseTicket(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to assign ticket');
  }

  @override
  Future<TicketModel> updateTicketStatus(String token, String ticketId, String status) async {
    final response = await client.put(
      Uri.parse(ApiConstants.ticketStatus(ticketId)),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return _parseTicket(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to update status');
  }

  @override
  Future<TicketModel> resolveTicket(String token, String ticketId) async {
    final response = await client.post(
      Uri.parse(ApiConstants.ticketResolve(ticketId)),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return _parseTicket(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to resolve ticket');
  }

  @override
  Future<TicketModel> closeTicket(String token, String ticketId) async {
    final response = await client.post(
      Uri.parse(ApiConstants.ticketClose(ticketId)),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return _parseTicket(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to close ticket');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllHistory(String token) async {
    final response = await client.get(
      Uri.parse(ApiConstants.history),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch all history');
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String token, String ticketId) async {
    final response = await client.get(
      Uri.parse(ApiConstants.ticketComments(ticketId)),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to fetch comments');
  }

  @override
  Future<Map<String, dynamic>> addComment(
    String token,
    String ticketId,
    String content, {
    String? parentCommentId,
  }) async {
    final response = await client.post(
      Uri.parse(ApiConstants.ticketComments(ticketId)),
      headers: _headers(token),
      body: jsonEncode({
        'message': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body['success'] == true) {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to add comment');
  }

  @override
  Future<void> deleteComment(String token, String ticketId, String commentId) async {
    final response = await client.delete(
      Uri.parse('${ApiConstants.ticketComments(ticketId)}/$commentId'),
      headers: _headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete comment');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String token,
    String ticketId,
    List<int> fileBytes,
    String filename,
  ) async {
    // Determine content type from filename extension
    final ext = filename.toLowerCase().split('.').last;
    String contentType;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
      case 'txt':
        contentType = 'text/plain';
        break;
      default:
        contentType = 'application/octet-stream';
    }

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.ticketAttachments(ticketId)),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));


    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body['message'] != null) {
      return body;
    }
    throw Exception(body['error'] ?? 'Failed to upload attachment');
  }

  // Helper to parse ticket from JSON
  TicketModel _parseTicket(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: TicketPriority.values.firstWhere(
        (e) => e.label == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.label == json['status'],
        orElse: () => TicketStatus.open,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      assignedTo: json['assignedTo'],
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      attachments: List<String>.from(json['attachments'] ?? []),
      comments: [],
      history: [],
    );
  }
}