import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'crm_overview_page.dart';
import 'crm_cases_page.dart';
import '../customer/profile_page.dart';
import 'crm_drawer.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<AuthService>().userProfile;
    final roleName = userProfile?.role.name.toUpperCase() ?? 'STAFF';

    final dbService = context.watch<DatabaseService>();
    final cases = dbService.cases;

    final pages = [
      const CrmOverviewPage(),
      CrmCasesPage(cases: cases),
      if (userProfile != null) ProfilePage(user: userProfile) else const Center(child: Text('Loading Profile...')),
    ];

    return Scaffold(
      drawer: const CrmDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.shield, color: Color(0xFF0F172A), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'GharBook - $roleName',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: AppColors.slate400,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Case Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'Biometrics'),
        ],
      ),
    );
  }
}
