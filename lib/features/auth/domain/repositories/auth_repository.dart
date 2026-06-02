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
}