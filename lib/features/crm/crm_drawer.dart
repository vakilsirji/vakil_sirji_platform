import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'leads_page.dart';
import 'clients_page.dart';
import 'crm_properties_page.dart';
import 'crm_cases_page.dart';
import 'crm_documents_page.dart';
import 'crm_payments_page.dart';
import '../admin/admin_staff_management_page.dart';
import '../../models/user_profile.dart';
import 'package:go_router/go_router.dart';

class CrmDrawer extends StatelessWidget {
  const CrmDrawer({super.key});

  void _showComingSoon(BuildContext context, String moduleName) {
    Navigator.pop(context); // Close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName module is coming soon!'),
        backgroundColor: AppColors.slate700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<AuthService>().userProfile;
    final name = userProfile?.name ?? 'CRM User';
    final role = userProfile?.role.name.toUpperCase() ?? 'STAFF';

    return Drawer(
      backgroundColor: AppColors.slate50,
      width: 280, // Takes up ~25% of the screen instead of 85%
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            color: const Color(0xFF0F172A),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GHARBOOK $role',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // GLOBAL SEARCH
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '🔍 Search Global...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (val) =>
                            _showComingSoon(context, 'Global Search'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SCROLLABLE MODULE LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.dashboard,
                    color: Color(0xFF0F172A),
                  ),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                    ); // Close drawer to show the dashboard
                  },
                ),
                const Divider(height: 1, color: AppColors.slate200),
                _buildDirectModule(context, '📋 Leads'),
                _buildDirectModule(context, '👥 Clients'),
                _buildDirectModule(context, '🏢 Properties'),
                _buildDirectModule(context, '📄 Service Requests'),
                _buildDirectModule(context, '📁 Cases'),
                _buildDirectModule(context, '📝 Data Entry'),
                _buildDirectModule(context, '✅ Verification'),
                _buildDirectModule(context, '📅 Biometric Visits'),
                _buildDirectModule(context, '📜 Government Registration'),
                _buildDirectModule(context, '💰 Payments'),
                _buildDirectModule(context, '📂 Documents'),
                _buildDirectModule(context, '📢 Notifications'),
                _buildDirectModule(context, '👨‍💼 Staff'),
                _buildDirectModule(context, '📈 Reports'),
                _buildDirectModule(context, '⚙ Settings'),
                _buildDirectModule(context, '📊 Dashboard Widgets'),
                _buildDirectModule(context, '📜 Activity Timeline'),
              ],
            ),
          ),

          // LOGOUT FOOTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.slate200)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Secure Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await context.read<AuthService>().signOut();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectModule(BuildContext context, String title) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 16,
            color: AppColors.slate400,
          ),
          onTap: () {
            if (title.contains('Leads')) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Leads')),
                    body: const LeadsPage(initialFilter: 'All'),
                  ),
                ),
              );
            } else if (title.contains('Clients')) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Clients')),
                    body: const ClientsPage(initialFilter: 'All'),
                  ),
                ),
              );
            } else if (title.contains('Properties')) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Properties')),
                    body: const CrmPropertiesPage(),
                  ),
                ),
              );
            } else if (title.contains('Cases') || title.contains('Service')) {
              Navigator.pop(context);
              final cases = context.read<DatabaseService>().cases;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Service Requests')),
                    body: CrmCasesPage(cases: cases),
                  ),
                ),
              );
            } else if (title.contains('Documents')) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Documents')),
                    body: const CrmDocumentsPage(),
                  ),
                ),
              );
            } else if (title.contains('Payments')) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Payments')),
                    body: const CrmPaymentsPage(),
                  ),
                ),
              );
            } else if (title.contains('Staff')) {
              final userProfile = context.read<AuthService>().userProfile;
              if (userProfile?.role == UserRole.admin) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminStaffManagementPage(),
                  ),
                );
              } else {
                _showComingSoon(context, 'Staff Directory');
              }
            } else {
              _showComingSoon(context, title);
            }
          },
        ),
        const Divider(height: 1, color: AppColors.slate200),
      ],
    );
  }
}
