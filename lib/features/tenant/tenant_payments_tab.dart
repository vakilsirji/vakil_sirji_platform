import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/payment.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../customer/payments_tracker_page.dart'; // To reuse ReceiptModal

class TenantPaymentsTab extends StatelessWidget {
  final List<Payment> payments;
  final Tenant? tenantInfo;
  final Property? property;
  final bool isLoading;

  const TenantPaymentsTab({
    super.key,
    required this.payments,
    required this.tenantInfo,
    required this.property,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tenantInfo == null || property == null) {
      return const Center(
        child: Text(
          'No property or tenant info available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent & Payments',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            color: AppColors.slate900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MONTHLY RENT',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${property!.rentAmount.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Due by the ${property!.reminderDueDay}th of every month',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Payment History & Receipts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (payments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.slate300, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No payments recorded yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...payments.map((p) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.slate200),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.status == 'Paid'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      p.status == 'Paid' ? Icons.check_circle : Icons.pending,
                      color: p.status == 'Paid' ? Colors.green : Colors.amber,
                    ),
                  ),
                  title: Text(
                    p.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Date: ${p.paymentDate}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${p.amount.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (p.status == 'Paid')
                        const Text(
                          'Tap for Receipt',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    if (p.status == 'Paid') {
                      showDialog(
                        context: context,
                        builder: (ctx) => ReceiptModal(
                          payment: p,
                          property: property!,
                          tenant: tenantInfo!,
                        ),
                      );
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
