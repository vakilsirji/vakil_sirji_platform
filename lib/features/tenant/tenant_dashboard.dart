import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../customer/profile_page.dart';
import 'tenant_home_tab.dart';
import 'tenant_payments_tab.dart';
import 'tenant_documents_tab.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  int _currentIndex = 0;
  late UserProfile _currentUser;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _currentUser = context.read<AuthService>().userProfile!;
      Future.microtask(() {
        context.read<DatabaseService>().clearData();
        context.read<DatabaseService>().fetchTenantDashboardData(_currentUser.mobile);
      });
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();

    final pages = [
      TenantHomeTab(
        tenantInfo: dbService.currentTenantInfo,
        property: dbService.currentTenantProperty,
        isLoading: dbService.isLoading,
      ),
      TenantPaymentsTab(
        payments: dbService.payments,
        tenantInfo: dbService.currentTenantInfo,
        property: dbService.currentTenantProperty,
        isLoading: dbService.isLoading,
      ),
      TenantDocumentsTab(
        documents: dbService.documents,
        isLoading: dbService.isLoading,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'GharBook - Tenant',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(user: _currentUser, isStandalone: true)));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.slate300.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0F172A),
            unselectedItemColor: AppColors.slate400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'My Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Rent & Payments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'Documents',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
