import 'package:flutter/material.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
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
              'Terms & Conditions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: Juli 2026',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using this E-Ticketing Helpdesk application, you accept and agree to be bound by the terms and provision of this agreement.',
              isDark,
            ),
            _buildSection(
              context,
              '2. Use of Service',
              'You agree to use the service only for lawful purposes and in a way that does not infringe on the rights of, restrict, or inhibit anyone else\'s use and enjoyment of the service.',
              isDark,
            ),
            _buildSection(
              context,
              '3. User Responsibilities',
              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
              isDark,
            ),
            _buildSection(
              context,
              '4. Ticket Submission',
              'When submitting a ticket, you agree to provide accurate information and not submit false, fraudulent, or malicious content.',
              isDark,
            ),
            _buildSection(
              context,
              '5. Privacy',
              'Your use of this service is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices.',
              isDark,
            ),
            _buildSection(
              context,
              '6. Intellectual Property',
              'The service and original content, features, and functionality are and will remain the exclusive property of the application developers.',
              isDark,
            ),
            _buildSection(
              context,
              '7. Limitation of Liability',
              'In no event shall the developers be liable for any indirect, incidental, special, consequential, or punitive damages.',
              isDark,
            ),
            _buildSection(
              context,
              '8. Changes to Terms',
              'We reserve the right to modify these terms at any time. We will provide notice of significant changes via the application.',
              isDark,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'For questions, contact: support@e-ticketing.com',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
