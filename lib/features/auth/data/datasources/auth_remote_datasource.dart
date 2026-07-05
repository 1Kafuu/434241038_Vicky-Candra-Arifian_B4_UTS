import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> getCurrentUser(String token);
  Future<void> logout(String token);
  Future<List<Map<String, dynamic>>> getHelpdesks(String token);
  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'];
    }

    throw Exception(body['message'] ?? 'Login failed');
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return body['data'];
    }

    throw Exception(body['message'] ?? 'Registration failed');
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await client.get(
      Uri.parse(ApiConstants.me),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data']['user'];
    }

    throw Exception(body['message'] ?? 'Failed to get user');
  }

  @override
  Future<void> logout(String token) async {
    final response = await client.post(
      Uri.parse(ApiConstants.logout),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Logout failed');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHelpdesks(String token) async {
    final response = await client.get(
      Uri.parse(ApiConstants.helpdesks),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }

    throw Exception(body['message'] ?? 'Failed to fetch helpdesk list');
  }

  @override
  Future<void> resetPassword(String email) async {
    final response = await client.post(
      Uri.parse(ApiConstants.forgotPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Reset password failed');
    }
  }
}
