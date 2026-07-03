import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  final bool isStandalone;

  const ProfilePage({super.key, required this.user, this.isStandalone = false});

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF0F172A),
              child: Icon(Icons.person, size: 40, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(user.role.name.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Personal Information'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            shadowColor: AppColors.slate200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email_outlined, 'Email Address', user.email),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(Icons.phone_outlined, 'Mobile Number', user.mobile),
                  if (user.address != null) ...[
                    const Divider(height: 24, thickness: 0.5),
                    _buildInfoRow(Icons.location_on_outlined, 'Registered Address', user.address!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Identity & Documents'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            shadowColor: AppColors.slate200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (user.aadhaar != null) ...[
                    _buildInfoRow(Icons.badge_outlined, 'Aadhaar UID', user.aadhaar!),
                    const Divider(height: 24, thickness: 0.5),
                  ],
                  if (user.pan != null) ...[
                    _buildInfoRow(Icons.credit_card_outlined, 'PAN Card', user.pan!),
                    const Divider(height: 24, thickness: 0.5),
                  ],
                  _buildInfoRow(Icons.date_range_outlined, 'Joined Date', user.joinedDate),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              await context.read<AuthService>().signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (isStandalone) {
      return Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          title: const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: content,
      );
    }
    return content;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate500)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 10)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }
}
