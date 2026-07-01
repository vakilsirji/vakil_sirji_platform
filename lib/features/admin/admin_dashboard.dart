import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/user_profile.dart';
import '../../models/payment.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'admin_overview_page.dart';
import '../crm/crm_cases_page.dart';
import '../customer/properties_page.dart';
import '../customer/payments_tracker_page.dart';
import '../customer/profile_page.dart';
import '../../services/database_service.dart';
import '../crm/crm_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  late UserProfile _currentUser;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    final dbService = context.read<DatabaseService>();
    if (authService.userProfile != null && !_initialized) {
      _currentUser = authService.userProfile!;
      _initialized = true;
      if (dbService.properties.isEmpty && !dbService.isLoading) {
        Future.microtask(() => dbService.fetchAdminDashboardData());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    
    if (dbService.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text('Syncing with GharBook Servers...'),
            ],
          ),
        ),
      );
    }

    final properties = dbService.properties;
    final cases = dbService.cases;
    final payments = dbService.payments;

    final List<Widget> pages = [
      AdminOverviewPage(properties: properties, payments: payments, cases: cases),
      CrmCasesPage(cases: cases),
      ProfilePage(user: _currentUser),
    ];

    return Scaffold(
      backgroundColor: AppColors.slate50,
      drawer: const CrmDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'GharBook - Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.redAccent, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: AppColors.slate400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'CRM Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}
