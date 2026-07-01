import 'package:flutter/material.dart';
import '../../core/constants.dart';

class CrmOverviewPage extends StatelessWidget {
  const CrmOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Pending Cases', '12', Colors.amber.shade700),
              _buildStatCard('Completed Today', '8', AppColors.emerald600),
              _buildStatCard('Biometrics Due', '5', Colors.blue.shade700),
              _buildStatCard('Police Verifs', '3', Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildActivityItem('Case #REQ_102 Draft Generated', '2 mins ago', Icons.description),
          _buildActivityItem('Biometric Completed for Tenant: Rohan', '15 mins ago', Icons.fingerprint),
          _buildActivityItem('New Rent Agreement Request', '1 hour ago', Icons.add_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.slate200)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.slate100, child: Icon(icon, color: const Color(0xFF0F172A), size: 20)),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
      ),
    );
  }
}
