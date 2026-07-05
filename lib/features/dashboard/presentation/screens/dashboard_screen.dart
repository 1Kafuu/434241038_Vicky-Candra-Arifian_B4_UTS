import 'package:flutter/material.dart' hide TextField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/text_field.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/presentation/screens/create_ticket_screen.dart';
import '../../../tickets/presentation/screens/ticket_list_screen.dart';
import '../../../tickets/presentation/screens/ticket_detail_screen.dart';
import '../../../tickets/presentation/screens/ticket_history_screen.dart';
import '../../../tickets/presentation/widgets/ticket_card.dart';
import '../../../dashboard/presentation/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(ticketStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // Meniru bagian kiri AppBar: Welcome User
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi ${user?.name ?? 'User'}!", style: textTheme.headlineLarge),
            Text("Good Morning", style: textTheme.bodyMedium),
            Text(
              "Role: ${user?.role.name.toUpperCase() ?? '-'}",
              style: textTheme.bodySmall,
            ),
          ],
        ),
         actions: [
           // Meniru tombol lonceng notifikasi (FR-007)
           IconButton(
             onPressed: () {}, // Logika ke halaman notifikasi
             icon: Icon(Icons.notifications_none, color: Theme.of(context).colorScheme.onSurface),
           ),
           IconButton(
             onPressed: () async {
               await ref.read(authRepositoryProvider).logout();
               ref.read(currentUserProvider.notifier).setUser(null);
               if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (context) => const LoginScreen()),
                   (route) => false,
                 );
               }
             },
             icon: const Icon(Icons.logout),
           ),
         ],
      ),

       // Floating Action Button sesuai referensi (FR-005: Membuat tiket)
       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
       floatingActionButton: FloatingActionButton(
         onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
           );
         },
         backgroundColor: Theme.of(context).colorScheme.primary,
         elevation: 10,
         shape: const CircleBorder(),
         child: const Icon(Icons.add, color: Colors.white, size: 30),
       ),

      // Bottom Navigation Bar sesuai referensi
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlobalHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 48), // Spacer untuk Notch FAB
              IconButton(
                icon: const Icon(Icons.payment_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TicketListScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_pin_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ticketListProvider.future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Section Statistik (FR-008)
              const SizedBox(height: 8),
              _buildStatCards(context, textTheme, stats),

              // 2. Baris Search
              const SizedBox(height: 24),
              _buildSearchSection(context, ref),

              // 3. Banner "Welcome" sesuai desain
              const SizedBox(height: 24),
              _buildWelcomeBanner(context),

              // 4. Section "Ongoing Tickets" sesuai desain
              const SizedBox(height: 24),
              _buildOngoingSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

    // Widget Helper: Search Section
    Widget _buildSearchSection(BuildContext context, WidgetRef ref) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return CustomTextField(
        label: "Search",
        hint: "Search tickets...",
        icon: Icons.search,
        onChanged: (value) {
          final allTickets = ref.read(ticketListProvider).when(
            data: (tickets) => tickets,
            loading: () => <TicketEntity>[],
            error: (_, __) => <TicketEntity>[],
          );
          ref.read(dashboardSearchProvider.notifier).search(value, allTickets);
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          hintText: "Search",
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          filled: true,
          fillColor: isDark ? Colors.grey.shade900 : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(25.0)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(25.0)),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }

    Widget _buildStatCards(BuildContext context, TextTheme textTheme, Map<String, int> stats) {
     // Langsung kembalikan Column/Grid tanpa SliverToBoxAdapter
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           "Tickets Summary",
           style: textTheme.titleMedium?.copyWith(
             fontWeight: FontWeight.bold,
             color: Theme.of(context).colorScheme.onSurface,
           ),
         ),
         const SizedBox(height: 16),
         GridView.count(
           shrinkWrap: true, // Wajib true karena di dalam ScrollView
           physics:
               const NeverScrollableScrollPhysics(), // Wajib agar scroll ditangani SingleChildScrollView
           crossAxisCount: 2,
           crossAxisSpacing: 16,
           mainAxisSpacing: 16,
           childAspectRatio: 1.4,
           children: [
              StatCard(
                title: "Total Tickets",
                count: stats['total'].toString(),
                icon: Icons.confirmation_number_outlined,
                color: Theme.of(context).colorScheme.secondary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              StatCard(
                title: "Status Open",
                count: stats['open'].toString(),
                icon: Icons.hourglass_empty_rounded,
                color: AppColors.warning,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              StatCard(
                title: "In Progress",
                count: stats['inProgress'].toString(),
                icon: Icons.sync_rounded,
                color: Theme.of(context).colorScheme.secondary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              StatCard(
                title: "Resolved",
                count: stats['resolved'].toString(),
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
           ],
         ),
       ],
     );
   }

   // Widget Helper: Welcome Banner
   Widget _buildWelcomeBanner(BuildContext context) {
     final isDark = Theme.of(context).brightness == Brightness.dark;
     final textTheme = Theme.of(context).textTheme;
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.all(16.0),
       decoration: BoxDecoration(
         color: isDark ? Colors.grey.shade900 : Colors.white,
         borderRadius: BorderRadius.circular(15.0),
         border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
       ),
      child: Row(
        children: [
          Image(
            image: const AssetImage(AssetConstants.welcomeIllustration),
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 80,
                height: 80,
                child: Icon(Icons.image),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome!", style: textTheme.titleLarge?.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                Text(
                  "Let's manage your tickets smoothly.",
                  style: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

   // Widget Helper: Ongoing Tickets Section
    Widget _buildOngoingSection(BuildContext context, WidgetRef ref) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final searchState = ref.watch(dashboardSearchProvider);
      final tickets = ref.watch(filteredTicketsProvider);

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                searchState.query.isEmpty ? "Tickets" : "Search Results",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TicketListScreen(),
                    ),
                  );
                },
                child: Text(
                  "view all",
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
         const SizedBox(height: 12),
         // GridView untuk meniru tata letak Ongoing Projects
         const SizedBox(height: 12),

         tickets.isEmpty
             ? const Center(
                 child: Padding(
                   padding: EdgeInsets.symmetric(vertical: 20),
                   child: Text("No tickets found"),
                 ),
               )
             : GridView.builder(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 2,
                   crossAxisSpacing: 16.0,
                   mainAxisSpacing: 16.0,
                   childAspectRatio: 0.8,
                 ),
                 itemCount: tickets.length > 4 && searchState.query.isEmpty
                     ? 4
                     : tickets.length,
                 itemBuilder: (context, index) {
                   final ticket = tickets[index];
                   return GestureDetector(
                     onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) =>
                               TicketDetailScreen(ticket: ticket),
                         ),
                       );
                     },
                     child: TicketCard(ticket: ticket),
                   );
                 },
               ),
       ],
      );
    }
}
