import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../../models/payment.dart';
import '../../models/legal_case.dart';
import '../../models/user_profile.dart';
import 'package:url_launcher/url_launcher.dart';

class OverviewPage extends StatelessWidget {
  final UserProfile user;
  final List<Property> properties;
  final List<Tenant> tenants;
  final List<Payment> payments;
  final List<LegalCase> cases;
  final Function(int)? onNavigateToTab;

  const OverviewPage({
    super.key,
    required this.user,
    required this.properties,
    required this.tenants,
    required this.payments,
    required this.cases,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final double totalRentThisMonth = payments
        .where((p) => p.status == 'Paid' && p.paymentDate.startsWith('2026-06'))
        .fold(0.0, (sum, p) => sum + p.amount);

    final int activeAgreementsCount = cases.where((c) => c.status != AgreementStatus.completed).length;

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning,';
      if (hour < 17) return 'Good Afternoon,';
      return 'Good Evening,';
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Gradient Header
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.amber.shade100,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(getGreeting(), style: const TextStyle(fontSize: 14, color: AppColors.slate300)),
                          Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildMetricsGrid(activeAgreementsCount, totalRentThisMonth),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                _buildSectionTitle('Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 32),

                // Recent Activity
                _buildSectionTitle('Recent Activity'),
                const SizedBox(height: 16),
                _buildRecentActivityList(),
                const SizedBox(height: 32),

                // Upcoming Reminders
                _buildSectionTitle('Upcoming Reminders'),
                const SizedBox(height: 16),
                _buildRemindersList(),
                const SizedBox(height: 32),

                // Support
                _buildSectionTitle('Need Help?'),
                const SizedBox(height: 16),
                _buildSupportSection(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5));
  }

  Widget _buildMetricsGrid(int activeAgreements, double rent) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard('Properties', '${properties.length}', Icons.business_outlined, onTap: () {
              if (onNavigateToTab != null) onNavigateToTab!(2);
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Tenants', '${tenants.length}', Icons.group_outlined, onTap: () {
              if (onNavigateToTab != null) onNavigateToTab!(3);
            })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Agreements', '$activeAgreements', Icons.description_outlined, onTap: () {
              if (onNavigateToTab != null) onNavigateToTab!(1);
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Rent Due', '₹${rent.toInt()}', Icons.payments_outlined, onTap: () {
              if (onNavigateToTab != null) onNavigateToTab!(4);
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.slate300, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: [
        _buildActionCard(Icons.add_home_work, 'Add Property', AppColors.emerald50, AppColors.emerald600, () {
          if (onNavigateToTab != null) onNavigateToTab!(2);
        }),
        _buildActionCard(Icons.person_add, 'Add Tenant', Colors.blue.shade50, Colors.blue.shade700, () {
          _showAddTenantDialog(context);
        }),
        _buildActionCard(Icons.upload_file, 'Record Existing Agreement', Colors.amber.shade50, Colors.amber.shade700, () {
          if (onNavigateToTab != null) onNavigateToTab!(1);
        }),
        _buildActionCard(Icons.edit_document, 'Create Agreement', Colors.purple.shade50, Colors.purple.shade700, () {
          if (onNavigateToTab != null) onNavigateToTab!(1);
        }),
      ],
    );
  }

  void _showAddTenantDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTenantForm(properties: properties),
    );
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Contact GharBook Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Call Us'),
              subtitle: const Text('+91 02269 719106'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('tel:+9102269719106'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red),
              title: const Text('Email Us'),
              subtitle: const Text('vakilsirji24x7@gmail.com'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('mailto:vakilsirji24x7@gmai.com'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('WhatsApp Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('https://wa.me/912269719106'));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: iconColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.slate200.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No recent activity', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.slate200.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No upcoming reminders', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('GharBook LegalTech', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Premium Customer Support', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showContactUs(context),
              icon: const Icon(Icons.support_agent, color: Colors.white),
              label: const Text('Contact Us', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSupportButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [BoxShadow(color: AppColors.slate100, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class AddTenantForm extends StatefulWidget {
  final List<Property> properties;
  final Tenant? existingTenant;
  const AddTenantForm({super.key, required this.properties, this.existingTenant});

  @override
  State<AddTenantForm> createState() => _AddTenantFormState();
}

class _AddTenantFormState extends State<AddTenantForm> {
  String? _selectedPropertyId;
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _emergNameCtrl = TextEditingController();
  final _emergNumCtrl = TextEditingController();
  final _moveInCtrl = TextEditingController();
  final _moveOutCtrl = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDob;
  DateTime? _selectedMoveIn;
  DateTime? _selectedMoveOut;

  @override
  void initState() {
    super.initState();
    if (widget.existingTenant != null) {
      final t = widget.existingTenant!;
      _selectedPropertyId = t.propertyId;
      _nameCtrl.text = t.name;
      _mobileCtrl.text = t.mobile;
      _emailCtrl.text = t.email ?? '';
      _addressCtrl.text = t.currentAddress ?? '';
      _panCtrl.text = t.pan ?? '';
      _aadhaarCtrl.text = t.aadhaar ?? '';
      _emergNameCtrl.text = t.emergencyContactName ?? '';
      _emergNumCtrl.text = t.emergencyContactNumber ?? '';
      _moveInCtrl.text = t.moveInDate ?? '';
      _moveOutCtrl.text = t.moveOutDate ?? '';
    } else if (widget.properties.isNotEmpty) {
      _selectedPropertyId = widget.properties.first.id;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectMoveDate(BuildContext context, bool isMoveIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        if (isMoveIn) {
          _selectedMoveIn = picked;
          _moveInCtrl.text = formattedDate;
        } else {
          _selectedMoveOut = picked;
          _moveOutCtrl.text = formattedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existingTenant != null ? 'Edit Tenant' : 'Add New Tenant', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPropertyId,
              decoration: const InputDecoration(labelText: 'Assign to Property'),
              items: widget.properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (val) => setState(() => _selectedPropertyId = val),
            ),
            const SizedBox(height: 10),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tenant Name')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number'))),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dobCtrl,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: const InputDecoration(labelText: 'Date of Birth (DOB)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _panCtrl, decoration: const InputDecoration(labelText: 'PAN Card Number'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _aadhaarCtrl, decoration: const InputDecoration(labelText: 'Aadhaar Number'))),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address on Aadhaar Card'), maxLines: 2),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _emergNameCtrl, decoration: const InputDecoration(labelText: 'Emergency Contact Name'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _emergNumCtrl, decoration: const InputDecoration(labelText: 'Emergency Number'))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _moveInCtrl, readOnly: true,
                    onTap: () => _selectMoveDate(context, true),
                    decoration: const InputDecoration(labelText: 'Move-in Date'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _moveOutCtrl, readOnly: true,
                    onTap: () => _selectMoveDate(context, false),
                    decoration: const InputDecoration(labelText: 'Move-out Date (Optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_selectedPropertyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a property first')));
                  return;
                }
                setState(() => _isLoading = true);
                try {
                  final dbService = context.read<DatabaseService>();
                  if (widget.existingTenant != null) {
                    await dbService.updateTenant(
                      widget.existingTenant!.id,
                      _selectedPropertyId!,
                      _nameCtrl.text,
                      _mobileCtrl.text,
                      _emailCtrl.text,
                      _addressCtrl.text,
                      _panCtrl.text,
                      _dobCtrl.text,
                      aadhaar: _aadhaarCtrl.text,
                      emergencyContactName: _emergNameCtrl.text,
                      emergencyContactNumber: _emergNumCtrl.text,
                      moveInDate: _moveInCtrl.text,
                      moveOutDate: _moveOutCtrl.text,
                    );
                  } else {
                    await dbService.addTenant(
                      _selectedPropertyId!,
                      _nameCtrl.text,
                      _mobileCtrl.text,
                      _emailCtrl.text,
                      _addressCtrl.text,
                      _panCtrl.text,
                      _dobCtrl.text,
                      aadhaar: _aadhaarCtrl.text,
                      emergencyContactName: _emergNameCtrl.text,
                      emergencyContactNumber: _emergNumCtrl.text,
                      moveInDate: _moveInCtrl.text,
                      moveOutDate: _moveOutCtrl.text,
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.existingTenant != null ? 'Tenant updated successfully!' : 'Tenant added successfully!'), backgroundColor: AppColors.emerald600),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), minimumSize: const Size(double.infinity, 44)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.existingTenant != null ? 'Save Changes' : 'Save Tenant', style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
