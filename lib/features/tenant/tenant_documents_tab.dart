import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/document.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantDocumentsTab extends StatelessWidget {
  final List<Document> documents;
  final bool isLoading;

  const TenantDocumentsTab({
    super.key,
    required this.documents,
    required this.isLoading,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tenantDocs = documents.where((d) => d.entityType == 'Tenant' || d.entityType == 'Property').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shared Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          
          if (tenantDocs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
              child: const Column(
                children: [
                  Icon(Icons.folder_off, color: AppColors.slate300, size: 48),
                  SizedBox(height: 12),
                  Text('No documents have been shared with you.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ...tenantDocs.map((doc) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.slate200)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.description, color: Colors.blue),
                  ),
                  title: Text(doc.documentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Tap to view or download', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.download_rounded, color: AppColors.slate400),
                  onTap: () => _launchUrl(doc.fileUrl),
                ),
              );
            }),
        ],
      ),
    );
  }
}
