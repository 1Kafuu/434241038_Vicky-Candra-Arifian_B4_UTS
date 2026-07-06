import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/button.dart';
import '../../../auth/domain/entities/role_enum.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/admin_user_provider.dart';
import 'admin_user_form_screen.dart';

class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  ConsumerState<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminUserProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(adminUserProvider.notifier).loadUsers(
      search: query.isEmpty ? null : query,
      role: _selectedRole,
    );
  }

  void _onRoleFilter(String? role) {
    setState(() {
      _selectedRole = role;
    });
    ref.read(adminUserProvider.notifier).loadUsers(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      role: role,
    );
  }

  void _showDeleteDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminUserProvider.notifier).deleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'User deleted' : 'Failed to delete user'),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminUserFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: "Search by name or email",
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleChip(null, 'All'),
                        const SizedBox(width: 8),
                        _buildRoleChip('admin', 'Admin'),
                        const SizedBox(width: 8),
                        _buildRoleChip('helpdesk', 'Helpdesk'),
                        const SizedBox(width: 8),
                        _buildRoleChip('user', 'User'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: LoadingWidget())
                  : state.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: ${state.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.read(adminUserProvider.notifier).loadUsers(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : state.users.isEmpty
                          ? const Center(child: Text('No users found'))
                          : RefreshIndicator(
                              onRefresh: () => ref.read(adminUserProvider.notifier).loadUsers(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.users.length,
                                itemBuilder: (context, index) {
                                  final user = state.users[index];
                                  return _buildUserCard(user, isDark);
                                },
                              ),
                            ),
            ),

            if (!state.isLoading && state.users.isNotEmpty)
              _buildPagination(state, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String? role, String label) {
    final isSelected = _selectedRole == role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onRoleFilter(role),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
    );
  }

  Widget _buildUserCard(UserEntity user, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildRoleBadge(user.role, isDark),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUserFormScreen(user: user),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(user);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role, bool isDark) {
    Color bgColor;
    Color textColor;
    switch (role) {
      case UserRole.admin:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case UserRole.helpdesk:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case UserRole.user:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPagination(AdminUserState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${state.total} users',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.page > 1
                    ? () => ref.read(adminUserProvider.notifier).loadUsers(
                          page: state.page - 1,
                          search: state.searchQuery,
                          role: state.roleFilter,
                        )
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Page ${state.page} of ${state.totalPages}'),
              IconButton(
                onPressed: state.page < state.totalPages
                    ? () => ref.read(adminUserProvider.notifier).loadUsers(
                          page: state.page + 1,
                          search: state.searchQuery,
                          role: state.roleFilter,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}