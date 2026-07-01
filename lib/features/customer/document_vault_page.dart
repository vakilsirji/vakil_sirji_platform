import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import 'dart:typed_data';

class DocumentVaultPage extends StatelessWidget {
  final List<Document> documents;
  final String currentUserId;

  const DocumentVaultPage({super.key, required this.documents, required this.currentUserId});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Categories according to MVP requirements
    final List<String> categories = [
      'Property papers',
      'Tax receipt',
      'Electricity bill',
      'Water bill',
      'Society documents',
      'Insurance papers',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Vault',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Securely store and access all your property and tenant related documents.',
                    style: TextStyle(color: AppColors.slate500, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  // Filter documents for this category
                  final categoryDocs = documents.where((d) => d.documentType.toLowerCase() == category.toLowerCase()).toList();

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        // Open category details / list documents
                        _showCategoryDocuments(context, category, categoryDocs, currentUserId);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getIconForCategory(category), size: 40, color: AppColors.slate700),
                            const SizedBox(height: 12),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryDocs.isNotEmpty ? AppColors.emerald500.withValues(alpha: 0.2) : AppColors.slate200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${categoryDocs.length} files',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: categoryDocs.isNotEmpty ? Colors.green.shade800 : AppColors.slate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _showCategoryDocuments(BuildContext context, String category, List<Document> docs, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryDocsSheet(category: category, docs: docs, userId: userId),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'property papers': return Icons.description;
      case 'tax receipt': return Icons.receipt_long;
      case 'electricity bill': return Icons.electric_bolt;
      case 'water bill': return Icons.water_drop;
      case 'society documents': return Icons.business;
      case 'insurance papers': return Icons.security;
      default: return Icons.folder;
    }
  }
}

class _CategoryDocsSheet extends StatefulWidget {
  final String category;
  final List<Document> docs;
  final String userId;

  const _CategoryDocsSheet({required this.category, required this.docs, required this.userId});

  @override
  State<_CategoryDocsSheet> createState() => _CategoryDocsSheetState();
}

class _CategoryDocsSheetState extends State<_CategoryDocsSheet> {
  bool _isUploading = false;

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Future<void> _uploadNewDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final fileBytes = result.files.first.bytes!;
      final fileName = result.files.first.name;

      setState(() {
        _isUploading = true;
      });

      try {
        final dbService = context.read<DatabaseService>();
        // Using 'user' entity_type for general vault documents for now,
        // unless they are explicitly linked to a property.
        final fileUrl = await dbService.uploadFileToBucket('documents', '${widget.userId}/${DateTime.now().millisecondsSinceEpoch}_$fileName', fileBytes);
        await dbService.uploadDocument(widget.userId, 'user', widget.category, fileUrl, widget.userId);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: widget.docs.isEmpty
                ? Center(child: Text('No ${widget.category} uploaded yet.', style: const TextStyle(color: AppColors.slate400)))
                : ListView.builder(
                    itemCount: widget.docs.length,
                    itemBuilder: (ctx, index) {
                      final d = widget.docs[index];
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file, color: Colors.indigo),
                        title: Text(d.fileUrl.split('/').last.split('_').last, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                        subtitle: Text('Uploaded on ${d.uploadedAt.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: AppColors.slate500),
                              onPressed: () => _launchUrl(d.fileUrl),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Document?'),
                                    content: const Text('Are you sure you want to delete this document?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true), 
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await context.read<DatabaseService>().deleteDocument(d.id, d.fileUrl);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted successfully.')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadNewDocument,
            icon: _isUploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add),
            label: Text(_isUploading ? 'Uploading...' : 'Upload New ${widget.category}'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
