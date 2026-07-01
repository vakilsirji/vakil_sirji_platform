import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../customer/customer_dashboard.dart';
import '../crm/staff_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../tenant/tenant_dashboard.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    if (authService.isAuthenticated) {
      // Role-based routing
      if (authService.userProfile != null) {
        final role = authService.userProfile!.role;
        if (role == UserRole.admin) {
          return const AdminDashboardScreen();
        } else if (role == UserRole.tenant) {
          return const TenantDashboardScreen();
        } else if (role == UserRole.owner) {
          return const CustomerDashboardScreen();
        } else {
          return const StaffDashboardScreen();
        }
      }
      
      // Show loading while fetching profile
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // slate50
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF0F172A)),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const LoginScreen();
    }
  }
}
