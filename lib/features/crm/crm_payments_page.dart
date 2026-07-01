import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/payment.dart';
import '../../services/database_service.dart';

class CrmPaymentsPage extends StatefulWidget {
  const CrmPaymentsPage({super.key});

  @override
  State<CrmPaymentsPage> createState() => _CrmPaymentsPageState();
}

class _CrmPaymentsPageState extends State<CrmPaymentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Paid', 'Failed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final payments = dbService.payments;

    final totalRevenue = payments.where((p) => p.status == 'Paid').fold(0.0, (sum, p) => sum + p.amount);
    final totalPending = payments.where((p) => p.status == 'Pending').fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Payments & Invoicing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.redAccent,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildFinancialSummary(totalRevenue, totalPending),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filteredPayments = tab == 'All'
                    ? payments
                    : payments.where((p) => p.status == tab).toList();
                return _buildPaymentsList(filteredPayments);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateInvoiceForm(context, dbService),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.request_quote, color: Colors.white),
        label: const Text('Generate Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFinancialSummary(double revenue, double pending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryBox('Total Revenue', '₹${revenue.toStringAsFixed(0)}', Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryBox('Pending Dues', '₹${pending.toStringAsFixed(0)}', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String amount, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentsList(List<Payment> paymentsList) {
    if (paymentsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            const Text('No transactions found.', style: TextStyle(color: AppColors.slate500, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentsList.length,
      itemBuilder: (context, index) {
        final payment = paymentsList[index];
        IconData statusIcon = Icons.pending_actions;
        Color statusColor = Colors.orange;

        if (payment.status == 'Paid') {
          statusIcon = Icons.check_circle;
          statusColor = Colors.green;
        } else if (payment.status == 'Failed') {
          statusIcon = Icons.error;
          statusColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text('₹${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(payment.description, style: const TextStyle(fontSize: 13, color: AppColors.slate700)),
                Text('Date: ${payment.paymentDate}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(payment.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  void _showGenerateInvoiceForm(BuildContext context, DatabaseService dbService) {
    final formKey = GlobalKey<FormState>();
    String entityType = 'Rent';
    String description = '';
    double amount = 0.0;
    String dummyEntityId = '00000000-0000-0000-0000-000000000000'; // Dummy ID

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Generate Invoice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: entityType,
                  decoration: const InputDecoration(labelText: 'Invoice Type', border: OutlineInputBorder()),
                  items: ['Rent', 'Service Fee', 'Legal Fee', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => entityType = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (double.tryParse(val) == null) return 'Must be a number';
                    return null;
                  },
                  onSaved: (val) => amount = double.parse(val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => description = val!,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        Navigator.pop(bottomSheetContext);
                        
                        try {
                          await dbService.generateInvoice(dummyEntityId, entityType, amount, description);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invoice generated successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error generating invoice: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Generate & Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
