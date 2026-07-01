import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../../models/payment.dart';

class PaymentsTrackerPage extends StatefulWidget {
  final List<Property> properties;
  final List<Tenant> tenants;
  final List<Payment> payments;
  final Future<void> Function(String, bool, int, String) onSaveReminderSettings;
  final Future<void> Function(Payment) onAddPayment;
  final VoidCallback? onCreateAgreement;

  const PaymentsTrackerPage({
    super.key, required this.properties, required this.tenants, required this.payments,
    required this.onSaveReminderSettings, required this.onAddPayment, this.onCreateAgreement,
  });

  @override
  State<PaymentsTrackerPage> createState() => _PaymentsTrackerPageState();
}

class _PaymentsTrackerPageState extends State<PaymentsTrackerPage> {
  String? _selectedPropertyId;
  String _paymentMonth = '';
  final List<String> _recentMonths = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _txnController = TextEditingController();
  String _paymentStatus = 'Paid';
  String _paymentMode = 'UPI/GPay';
  bool _reminderEnabled = false;
  int _reminderDueDay = 5;
  String _reminderChannel = 'WhatsApp';
  bool _isSaving = false;

  void _generateRecentMonths() {
    final now = DateTime.now();
    for (int i = -3; i <= 3; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      _recentMonths.add(DateFormat('MMMM yyyy').format(date));
    }
    _paymentMonth = _recentMonths[3]; // Current month
  }

  @override
  void initState() {
    super.initState();
    _generateRecentMonths();
    if (widget.properties.isNotEmpty) {
      _selectedPropertyId = widget.properties.first.id;
      _syncPropertyDetails();
    }
  }

  void _syncPropertyDetails() {
    if (_selectedPropertyId != null) {
      final prop = widget.properties.firstWhere((p) => p.id == _selectedPropertyId);
      _amountController.text = prop.rentAmount.toInt().toString();
      _reminderEnabled = prop.reminderEnabled;
      _reminderDueDay = prop.reminderDueDay;
      _reminderChannel = prop.reminderChannel;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _sendReminder(Tenant tenant, Property property) async {
    final amount = property.rentAmount.toInt();
    final message = 'Hello ${tenant.name},\n\nThis is a gentle reminder that your rent of ₹$amount for ${property.name} is due soon. Please make the payment at your earliest convenience to avoid any late fees.\n\nThank you!\n- GharBook automated reminder';
    
    final encodedMessage = Uri.encodeComponent(message);
    Uri? url;
    
    if (_reminderChannel == 'WhatsApp' || _reminderChannel == 'All') {
      // Basic format for WhatsApp API
      String mobile = tenant.mobile.replaceAll(RegExp(r'\D'), '');
      if (!mobile.startsWith('91')) {
        mobile = '91$mobile';
      }
      url = Uri.parse('https://wa.me/$mobile?text=$encodedMessage');
    } else if (_reminderChannel == 'Email') {
      url = Uri.parse('mailto:${tenant.email}?subject=Rent Reminder for ${property.name}&body=$encodedMessage');
    } else if (_reminderChannel == 'SMS') {
      url = Uri.parse('sms:${tenant.mobile}?body=$encodedMessage');
    }

    if (url != null) {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $_reminderChannel application.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.properties.isEmpty) {
      return const Center(child: Text('No properties available.'));
    }
    
    final selectedProperty = widget.properties.firstWhere((p) => p.id == _selectedPropertyId, orElse: () => widget.properties.first);
    final linkedTenant = selectedProperty.currentTenantId != null 
        ? widget.tenants.firstWhere((t) => t.id == selectedProperty.currentTenantId, orElse: () => widget.tenants.first) 
        : null;

    final propertyPayments = widget.payments.where((p) => p.entityId == selectedProperty.id && p.entityType == 'Rent').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent Collection & Reminders Hub',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedPropertyId,
            decoration: const InputDecoration(labelText: 'Select Property', border: OutlineInputBorder()),
            items: widget.properties.map((p) {
              return DropdownMenuItem<String>(value: p.id, child: Text(p.name, style: const TextStyle(fontSize: 12)));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedPropertyId = val;
                _syncPropertyDetails();
              });
            },
          ),
          const SizedBox(height: 16),
          if (linkedTenant == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade200), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('This property is vacant. Please assign a tenant from the Properties tab to track payments.', style: TextStyle(fontSize: 11, height: 1.4)),
                  ),
                ],
              ),
            )
          else ...[
            Card(
              color: AppColors.slate900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE TENANT', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 9)),
                    const SizedBox(height: 4),
                    Text(linkedTenant.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Phone: ${linkedTenant.mobile}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('Rent: ₹${selectedProperty.rentAmount.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (selectedProperty.agreementEndDate != null)
                          Text('Ends: ${selectedProperty.agreementEndDate}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        if (selectedProperty.agreementEndDate == null)
                          const SizedBox(),
                        Text('Deposit: ₹${selectedProperty.depositAmount.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Reminders Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                leading: const Icon(Icons.settings_suggest, color: Colors.indigo, size: 20),
                childrenPadding: const EdgeInsets.all(16),
                collapsedBackgroundColor: Colors.white,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.slate200)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.slate200)),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Auto-Reminders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: _reminderEnabled,
                    activeThumbColor: Colors.indigo,
                    onChanged: (bool value) => setState(() => _reminderEnabled = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _reminderDueDay,
                          decoration: const InputDecoration(labelText: 'Due Day'),
                          items: List.generate(28, (index) => index + 1).map((day) {
                            return DropdownMenuItem<int>(value: day, child: Text('Day $day', style: const TextStyle(fontSize: 11)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _reminderDueDay = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _reminderChannel,
                          decoration: const InputDecoration(labelText: 'Channel'),
                          items: ['WhatsApp', 'Email', 'SMS', 'All'].map((ch) {
                            return DropdownMenuItem<String>(value: ch, child: Text(ch, style: const TextStyle(fontSize: 11)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _reminderChannel = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSaveReminderSettings(selectedProperty.id, _reminderEnabled, _reminderDueDay, _reminderChannel);
                    },
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Save Reminder Config'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate100, foregroundColor: const Color(0xFF0F172A), elevation: 0, minimumSize: const Size(double.infinity, 38)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _sendReminder(linkedTenant, selectedProperty);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Preparing rent alert for ${linkedTenant.name} via $_reminderChannel...'), backgroundColor: Colors.amber.shade800),
                      );
                    },
                    icon: const Icon(Icons.send_outlined, size: 14, color: Colors.white),
                    label: const Text('Send Manual Reminder Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), minimumSize: const Size(double.infinity, 38)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_card, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Record Rent Collection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMonth,
                    decoration: const InputDecoration(labelText: 'Billing Month'),
                    items: _recentMonths.map((m) {
                      return DropdownMenuItem<String>(value: m, child: Text(m, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMonth = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['Paid', 'Pending', 'Failed'].map((st) {
                      return DropdownMenuItem<String>(value: st, child: Text(st, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentStatus = val);
                    },
                  ),
                  if (_paymentStatus == 'Paid') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMode,
                      decoration: const InputDecoration(labelText: 'Mode'),
                      items: ['UPI/GPay', 'Net Banking', 'Cash', 'Cheque'].map((md) {
                        return DropdownMenuItem<String>(value: md, child: Text(md, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMode = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _txnController,
                      decoration: const InputDecoration(labelText: 'Transaction Reference ID', border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () async {
                      final double? amt = double.tryParse(_amountController.text);
                      if (amt == null) return;
                      
                      // Check for duplicate entry for the same month
                      final alreadyExists = propertyPayments.any((p) => p.description.contains(_paymentMonth));
                      if (alreadyExists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('A rent entry for $_paymentMonth already exists.'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setState(() => _isSaving = true);
                      
                      final randomId = 'TXN${Random().nextInt(900000) + 100000}';
                      final pay = Payment(
                        id: 'pay_${Random().nextInt(10000)}',
                        entityId: selectedProperty.id,
                        entityType: 'Rent',
                        amount: amt,
                        status: _paymentStatus,
                        paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        transactionId: _paymentStatus == 'Paid' ? (_txnController.text.isNotEmpty ? _txnController.text : randomId) : null,
                        description: 'Rent for $_paymentMonth - ${selectedProperty.name} ($_paymentMode)',
                      );
                      
                      try {
                        await widget.onAddPayment(pay);
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald500, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Log Rent Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Property Rent Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            if (propertyPayments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
                child: const Column(
                  children: [
                    Icon(Icons.history_toggle_off, color: AppColors.slate300, size: 40),
                    SizedBox(height: 12),
                    Text('No rent payments logged yet.', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: propertyPayments.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.slate100),
                  itemBuilder: (context, index) {
                    final p = propertyPayments[index];
                    return InkWell(
                      onTap: () {
                        if (p.status == 'Paid') {
                          showDialog(
                            context: context,
                            builder: (ctx) => ReceiptModal(payment: p, property: selectedProperty, tenant: linkedTenant),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: p.status == 'Paid' ? Colors.green.shade50 : Colors.amber.shade50, shape: BoxShape.circle),
                              child: Icon(
                                p.status == 'Paid' ? Icons.check_circle : Icons.pending_actions,
                                color: p.status == 'Paid' ? Colors.green : Colors.amber.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  Text('Date: ${p.paymentDate} | Ref: ${p.transactionId ?? "Pending"}', style: const TextStyle(fontSize: 10, color: AppColors.slate500)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${p.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  p.status.toUpperCase(),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: p.status == 'Paid' ? Colors.green.shade700 : Colors.amber.shade800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ReceiptModal extends StatelessWidget {
  final Payment payment;
  final Property property;
  final Tenant tenant;

  const ReceiptModal({super.key, required this.payment, required this.property, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('GHARBOOK RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  const Text('RENT RECEIPT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  const SizedBox(height: 4),
                  Text('Receipt No: ${payment.id.toUpperCase()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Date of Payment: ${payment.paymentDate}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.5),
                children: [
                  const TextSpan(text: 'Received with thanks from '),
                  TextSpan(text: tenant.name, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  const TextSpan(text: ', the sum of Rupees '),
                  TextSpan(text: '₹${payment.amount.toInt()} Only', style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  const TextSpan(text: ' by way of electronic bank transfer towards the rent of '),
                  TextSpan(text: property.name, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  const TextSpan(text: ' located at '),
                  TextSpan(text: '${property.address}, ${property.city}.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRANSACTION REF', style: TextStyle(color: Colors.grey, fontSize: 9)),
                    Text(payment.transactionId ?? 'CASH', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Note: This is a computer generated receipt. No signature is required.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final message = 'Hi ${tenant.name},\n\nThis is to confirm receipt of your rent payment of Rs. ${payment.amount.toInt()} for ${property.name}.\n\nReference: ${payment.transactionId ?? "CASH"}\nDate: ${payment.paymentDate}\n\nYou can view the full receipt on your Tenant Dashboard.\n\nThank you!';
                final encodedMessage = Uri.encodeComponent(message);
                
                String formattedPhone = tenant.mobile.replaceAll(RegExp(r'\D'), '');
                if (formattedPhone.length == 10) {
                  formattedPhone = '91$formattedPhone';
                }

                final url = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encodedMessage');
                final webUrl = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else if (await canLaunchUrl(webUrl)) {
                    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                    }
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Redirecting to WhatsApp! (Also visible on Tenant Dashboard)'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Send to Tenant (WhatsApp & Dash)'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        ),
      ),
    );
  }
}
