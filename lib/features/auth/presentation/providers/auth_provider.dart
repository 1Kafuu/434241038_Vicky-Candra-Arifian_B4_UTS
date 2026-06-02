import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../../../core/providers/shared_prefs_provider.dart';

// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// AuthRemoteDataSource provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return AuthRemoteDataSourceImpl(client: client);
});

// AuthRepository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sharedPreferences: prefs,
  );
});

// Current user state
final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserEntity?>(() {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends Notifier<UserEntity?> {
  @override
  UserEntity? build() {
    return null;
  }

  void setUser(UserEntity? user) {
    state = user;
  }
}

// Fetch list of helpdesks provider
final helpdeskListProvider = FutureProvider<List<UserEntity>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getHelpdeskUsers();
});
