import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/lead.dart';
import '../../services/database_service.dart';

class LeadsPage extends StatefulWidget {
  final String initialFilter;

  const LeadsPage({super.key, this.initialFilter = 'New Lead'});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = [
    'New Lead',
    'Follow-up',
    'Interested',
    'Not Interested',
    'Converted',
    'Lost'
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _statuses.indexOf(widget.initialFilter);
    if (initialIndex == -1) initialIndex = 0;
    
    _tabController = TabController(length: _statuses.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final allLeads = dbService.leads;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Leads Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.redAccent,
          tabs: _statuses.map((status) {
            final count = allLeads.where((l) => l.status == status).length;
            return Tab(
              child: Row(
                children: [
                  Text(status),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          final leadsForStatus = allLeads.where((l) => l.status == status).toList();
          return _buildLeadList(leadsForStatus, status, dbService);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLeadForm(context, dbService),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLeadList(List<Lead> leads, String currentStatus, DatabaseService dbService) {
    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text('No leads in "$currentStatus"', style: const TextStyle(color: AppColors.slate500, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = leads[index];
        return _buildLeadCard(lead, dbService);
      },
    );
  }

  Widget _buildLeadCard(Lead lead, DatabaseService dbService) {
    IconData sourceIcon = Icons.web;
    Color sourceColor = Colors.blue;

    if (lead.source.toLowerCase().contains('whatsapp')) {
      sourceIcon = Icons.chat;
      sourceColor = Colors.green;
    } else if (lead.source.toLowerCase().contains('phone')) {
      sourceIcon = Icons.phone;
      sourceColor = Colors.orange;
    } else if (lead.source.toLowerCase().contains('facebook')) {
      sourceIcon = Icons.facebook;
      sourceColor = Colors.blueAccent;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: sourceColor.withValues(alpha: 0.1),
                      child: Icon(sourceIcon, color: sourceColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lead.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(lead.mobile, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.slate500),
                  onSelected: (newStatus) {
                    dbService.updateLeadStatus(lead.id, newStatus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lead moved to $newStatus')),
                    );
                  },
                  itemBuilder: (context) {
                    return _statuses.where((s) => s != lead.status).map((status) {
                      return PopupMenuItem<String>(
                        value: status,
                        child: Text('Move to $status'),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            if (lead.notes != null && lead.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Text(
                  lead.notes!,
                  style: const TextStyle(color: AppColors.slate700, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${lead.createdAt.toLocal().toString().substring(0, 10)}',
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                ),
                Text(
                  'Source: ${lead.source}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate600, fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddLeadForm(BuildContext context, DatabaseService dbService) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String mobile = '';
    String source = 'Phone Call';
    String status = 'New Lead';
    String notes = '';

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
                const Text('Add New Lead', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => name = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => mobile = val!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: source,
                  decoration: const InputDecoration(labelText: 'Source', border: OutlineInputBorder()),
                  items: ['Website', 'WhatsApp', 'Phone Call', 'Facebook'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => source = val!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => status = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                  onSaved: (val) => notes = val ?? '',
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
                          await dbService.addLead(name, mobile, source, status, notes);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lead added successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error adding lead: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Save Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
