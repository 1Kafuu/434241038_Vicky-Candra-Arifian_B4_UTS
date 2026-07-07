import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/theme/theme_provider.dart';
import 'faq_screen.dart';
import 'terms_screen.dart';
import 'package:e_ticketing/features/auth/presentation/screens/login_screen.dart';
import 'package:e_ticketing/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              subtitle: ref.watch(themeProvider) == ThemeMode.dark
                  ? 'Currently using Dark Mode'
                  : 'Currently using Light Mode',
              trailing: Switch(
                value: ref.watch(themeProvider) == ThemeMode.dark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            Text(
              'Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: Icons.help_outline,
              label: 'FAQ',
              subtitle: 'Frequently Asked Questions',
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FaqScreen()),
              ),
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              subtitle: 'Read our terms and policies',
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsScreen()),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: Icons.logout,
              label: 'Logout',
              subtitle: 'Sign out from your account',
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.error,
              ),
              onTap: () => _handleLogout(context, ref),
              isDark: isDark,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Widget trailing,
    required bool isDark,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : (isDark ? Colors.white : Colors.black),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(currentUserProvider.notifier).setUser(null);

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
