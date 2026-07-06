import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/document.dart';
import '../../services/database_service.dart';

class CrmDocumentsPage extends StatefulWidget {
  const CrmDocumentsPage({super.key});

  @override
  State<CrmDocumentsPage> createState() => _CrmDocumentsPageState();
}

class _CrmDocumentsPageState extends State<CrmDocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'All',
    'Properties',
    'Owners',
    'Tenants',
    'Agreements',
  ];

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
    final documents = dbService.documents;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Documents Vault',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.redAccent,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          final filteredDocs = tab == 'All'
              ? documents
              : documents
                    .where(
                      (d) =>
                          d.entityType.toLowerCase() ==
                          tab
                              .toLowerCase()
                              .replaceAll('ies', 'y')
                              .replaceAll('s', ''),
                    )
                    .toList();
          return _buildDocumentsList(filteredDocs);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadForm(context, dbService),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text(
          'Upload',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDocumentsList(List<Document> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            const Text(
              'No documents found.',
              style: TextStyle(color: AppColors.slate500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        IconData docIcon = Icons.insert_drive_file;
        if (doc.documentType.toLowerCase().contains('aadhaar') ||
            doc.documentType.toLowerCase().contains('pan')) {
          docIcon = Icons.badge;
        } else if (doc.documentType.toLowerCase().contains('bill')) {
          docIcon = Icons.receipt;
        } else if (doc.documentType.toLowerCase().contains('agreement')) {
          docIcon = Icons.handshake;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: Icon(docIcon, color: Colors.blueAccent),
            ),
            title: Text(
              doc.documentType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Type: ${doc.entityType}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
                Text(
                  'Uploaded: ${doc.uploadedAt.toLocal().toString().substring(0, 10)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download, color: AppColors.slate400),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading ${doc.documentType}...')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showUploadForm(BuildContext context, DatabaseService dbService) {
    final formKey = GlobalKey<FormState>();
    String entityType = 'Property';
    String documentType = 'Aadhaar';
    // We'll use a dummy ID for now since we're not building a complex entity picker
    String dummyEntityId = '00000000-0000-0000-0000-000000000000';
    String dummyUserId = '33333333-3333-3333-3333-333333333333'; // staff ID

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
                const Text(
                  'Upload New Document',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: entityType,
                  decoration: const InputDecoration(
                    labelText: 'Linked Entity',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Property', 'Owner', 'Tenant', 'Agreement']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => entityType = val!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: documentType,
                  decoration: const InputDecoration(
                    labelText: 'Document Type',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'Aadhaar',
                            'PAN',
                            'Electricity Bill',
                            'Rent Agreement',
                            'Other',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) => documentType = val!,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.slate300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: AppColors.slate400,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select file',
                        style: TextStyle(color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(bottomSheetContext);

                        try {
                          await dbService.uploadDocument(
                            dummyEntityId,
                            entityType,
                            documentType,
                            'https://example.com/dummy_$documentType.pdf',
                            dummyUserId,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Document uploaded successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error uploading document: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'Upload to Vault',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
