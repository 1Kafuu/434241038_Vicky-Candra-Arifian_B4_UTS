import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/entities/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PaginatedUsers {
  final List<UserEntity> users;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedUsers({
    required this.users,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}

class AdminUserState {
  final List<UserEntity> users;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? roleFilter;

  const AdminUserState({
    this.users = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 10,
    this.totalPages = 0,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.roleFilter,
  });

  AdminUserState copyWith({
    List<UserEntity>? users,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? roleFilter,
  }) {
    return AdminUserState(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
    );
  }
}

class AdminUserNotifier extends Notifier<AdminUserState> {
  @override
  AdminUserState build() {
    return const AdminUserState();
  }

  Future<void> loadUsers({int page = 1, String? search, String? role}) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: search, roleFilter: role);
    try {
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.getUsers(page: page, limit: state.limit, search: search, role: role);
      state = state.copyWith(
        users: (data['users'] as List).map((json) => _userFromJson(json)).toList(),
        total: data['total'] ?? 0,
        page: data['page'] ?? 1,
        limit: data['limit'] ?? 10,
        totalPages: data['totalPages'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createUser({required String name, required String email, required String password, required String role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.createUser(name: name, email: email, password: password, role: role);
      if (user != null) {
        await loadUsers(page: state.page, search: state.searchQuery, role: state.roleFilter);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to create user');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateUser(String id, {String? name, String? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.updateUser(id, name: name, role: role);
      if (user != null) {
        await loadUsers(page: state.page, search: state.searchQuery, role: state.roleFilter);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to update user');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final success = await repo.deleteUser(id);
      if (success) {
        await loadUsers(page: state.page, search: state.searchQuery, role: state.roleFilter);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to delete user');
      return false;
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Cannot delete your own account')) {
        state = state.copyWith(isLoading: false, error: 'Cannot delete your own account');
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete user');
      }
      return false;
    }
  }

  UserEntity _userFromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'user'),
      profileImage: json['profileImage'],
    );
  }
}

final adminUserProvider = NotifierProvider<AdminUserNotifier, AdminUserState>(() {
  return AdminUserNotifier();
});
