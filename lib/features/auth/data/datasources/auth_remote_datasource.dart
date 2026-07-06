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
  Future<void> forgotPassword(String email);
  Future<bool> verifyOtp(String email, String otp);
  Future<bool> resetPassword(String email, String otp, String newPassword);
  Future<Map<String, dynamic>> getUsers(String token, {int page = 1, int limit = 10, String? search, String? role});
  Future<Map<String, dynamic>> getUserById(String token, String id);
  Future<Map<String, dynamic>> createUser(String token, {required String name, required String email, required String password, required String role});
  Future<Map<String, dynamic>> updateUser(String token, String id, {String? name, String? role});
  Future<void> deleteUser(String token, String id);
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
  Future<void> forgotPassword(String email) async {
    final response = await client.post(
      Uri.parse(ApiConstants.forgotPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to send OTP');
    }
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    final response = await client.post(
      Uri.parse(ApiConstants.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Invalid OTP');
    }

    return true;
  }

  @override
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    final response = await client.post(
      Uri.parse(ApiConstants.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to reset password');
    }

    return true;
  }

  @override
  Future<Map<String, dynamic>> getUsers(String token, {int page = 1, int limit = 10, String? search, String? role}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (role != null && role.isNotEmpty) {
      queryParams['role'] = role;
    }
    final uri = Uri.parse('${ApiConstants.adminUsers}').replace(queryParameters: queryParams);
    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to fetch users');
  }

  @override
  Future<Map<String, dynamic>> getUserById(String token, String id) async {
    final response = await client.get(
      Uri.parse(ApiConstants.adminUserById(id)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to fetch user');
  }

  @override
  Future<Map<String, dynamic>> createUser(String token, {required String name, required String email, required String password, required String role}) async {
    final response = await client.post(
      Uri.parse(ApiConstants.adminUsers),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201 && body['success'] == true) {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to create user');
  }

  @override
  Future<Map<String, dynamic>> updateUser(String token, String id, {String? name, String? role}) async {
    final bodyMap = <String, dynamic>{};
    if (name != null) bodyMap['name'] = name;
    if (role != null) bodyMap['role'] = role;

    final response = await client.patch(
      Uri.parse(ApiConstants.adminUserById(id)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyMap),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to update user');
  }

  @override
  Future<void> deleteUser(String token, String id) async {
    final response = await client.delete(
      Uri.parse(ApiConstants.adminUserById(id)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete user');
    }
  }
}
