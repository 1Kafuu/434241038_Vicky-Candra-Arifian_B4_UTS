import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

const String _tokenKey = 'auth_token';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  // ─── Save / Get / Clear token ─────────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  String? _getToken() {
    return sharedPreferences.getString(_tokenKey);
  }

  Future<void> _clearToken() async {
    await sharedPreferences.remove(_tokenKey);
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      final data = await remoteDataSource.login(email, password);

      // Save token locally
      await _saveToken(data['token']);

      // Parse and return user
      return UserModel.fromJson(data['user']);
    } catch (e) {
      return null;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  @override
  Future<UserEntity?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final data = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );

      // Save token if returned (auto-login after register)
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }

      return UserModel.fromJson(data['user']);
    } catch (e) {
      return null;
    }
  }

  // ─── Get Current User ─────────────────────────────────────────────────────

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = _getToken();
      if (token == null) return null;

      final userMap = await remoteDataSource.getCurrentUser(token);
      return UserModel.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      final token = _getToken();
      if (token != null) {
        await remoteDataSource.logout(token);
      }
    } catch (_) {
      // Even if API call fails, clear local token
    } finally {
      await _clearToken();
    }
  }

  @override
  Future<List<UserEntity>> getHelpdeskUsers() async {
    try {
      final token = _getToken();
      if (token == null) return [];

      final list = await remoteDataSource.getHelpdesks(token);
      return list.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
