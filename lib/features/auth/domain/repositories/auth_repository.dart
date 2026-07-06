import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> register({
    required String name,
    required String email,
    required String password,
  });
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
  Future<List<UserEntity>> getHelpdeskUsers();
  Future<bool> forgotPassword(String email);
  Future<bool> verifyOtp(String email, String otp);
  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword);
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 10, String? search, String? role});
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> createUser({required String name, required String email, required String password, required String role});
  Future<UserEntity?> updateUser(String id, {String? name, String? role});
  Future<bool> deleteUser(String id);
}