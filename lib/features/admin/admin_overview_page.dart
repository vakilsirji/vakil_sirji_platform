import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/payment.dart';
import '../../models/legal_case.dart';

class AdminOverviewPage extends StatelessWidget {
  final List<Property> properties;
  final List<Payment> payments;
  final List<LegalCase> cases;

  const AdminOverviewPage({
    super.key, 
    required this.properties, 
    required this.payments, 
    required this.cases,
  });

  @override
  Widget build(BuildContext context) {
    // Metric 1: Today's Cases
    final todaysDate = DateTime.now().toIso8601String().substring(0, 10);
    final todaysCasesCount = cases.where((c) => c.createdAt.startsWith(todaysDate)).length;
    
    // Metric 2: Today's Visits (Biometrics Scheduled)
    final todaysVisitsCount = cases.where((c) => c.status == AgreementStatus.biometricScheduled).length;

    // Metric 3: Pending Cases
    final pendingCasesCount = cases.where((c) => c.status != AgreementStatus.completed).length;

    // Metric 4: Revenue
    final revenue = payments.where((p) => p.status == 'Paid').fold(0.0, (sum, p) => sum + p.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTERNAL CRM',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
                ),
                SizedBox(height: 6),
                Text(
                  'Platform Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Track total cases, doorstep visits, and staff performance metrics.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // ROW 1
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Today\'s Cases',
                  value: '$todaysCasesCount',
                  icon: Icons.add_chart,
                  iconColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Today\'s Visits',
                  value: '$todaysVisitsCount',
                  icon: Icons.directions_walk,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ROW 2
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Pending Cases',
                  value: '$pendingCasesCount',
                  icon: Icons.pending_actions,
                  iconColor: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Revenue',
                  value: '₹${revenue.toInt()}',
                  icon: Icons.currency_rupee,
                  iconColor: AppColors.emerald500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Metric 5: Staff Performance
          const Row(
            children: [
              Icon(Icons.leaderboard, color: Color(0xFF0F172A), size: 20),
              SizedBox(width: 8),
              Text(
                'Staff Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStaffPerformanceCard('Rahul Sharma', 'Field Executive', 5, 2),
          _buildStaffPerformanceCard('Priya Desai', 'CRM Manager', 12, 8),
          _buildStaffPerformanceCard('Amit Kumar', 'Verification Officer', 8, 5),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStaffPerformanceCard(String name, String role, int casesProcessed, int biometricsDone) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.1),
              child: Text(name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(role, style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$casesProcessed Cases', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                Text('$biometricsDone Visits', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
