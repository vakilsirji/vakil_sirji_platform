import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import 'package:url_launcher/url_launcher.dart';

class AgreementsPage extends StatelessWidget {
  final List<LegalCase> cases;
  final VoidCallback? onRequestRenewal;
  final Function(String)? onDeleteAgreement;
  final Future<void> Function(String, String, Uint8List)? onUploadDocument;

  const AgreementsPage({
    super.key,
    required this.cases,
    this.onRequestRenewal,
    this.onDeleteAgreement,
    this.onUploadDocument,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  void _showDetailsSheet(BuildContext context, LegalCase c, DateTime startDate, DateTime endDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return _AgreementDetailsSheet(
          caseItem: c,
          startDate: startDate,
          endDate: endDate,
          onLaunchUrl: _launchUrl,
          onUploadDocument: onUploadDocument,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final agreements = cases.where((c) => c.serviceType.toLowerCase().contains('agreement')).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: agreements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 60, color: AppColors.slate300),
                  const SizedBox(height: 16),
                  const Text('No agreements found.', style: TextStyle(color: AppColors.slate500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: agreements.length,
              itemBuilder: (context, index) {
                final c = agreements[index];
                
                // Parse exact dates from details map if they exist
                DateTime? parsedStart;
                DateTime? parsedEnd;
                
                if (c.details != null) {
                  final startString = c.details!['existing_start_date']?.toString();
                  final endString = c.details!['existing_end_date']?.toString();
                  
                  if (startString != null && startString.isNotEmpty) {
                    parsedStart = DateTime.tryParse(startString.trim());
                  }
                  if (endString != null && endString.isNotEmpty) {
                    parsedEnd = DateTime.tryParse(endString.trim());
                  }
                }

                // Fallback to creation date + 330 days if not an existing agreement
                final startDate = parsedStart ?? DateTime.tryParse(c.createdAt) ?? DateTime.now();
                final endDate = parsedEnd ?? startDate.add(const Duration(days: 330)); // ~11 months
                final isExpiringSoon = endDate.difference(DateTime.now()).inDays < 30;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDetailsSheet(context, c, startDate, endDate),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  c.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.status == AgreementStatus.completed ? Colors.green.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: c.status == AgreementStatus.completed ? Colors.green.shade700 : Colors.amber.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.slate400),
                              const SizedBox(width: 8),
                              Text('Start: ${startDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.event_busy, size: 14, color: AppColors.slate400),
                              const SizedBox(width: 8),
                              Text('End: ${endDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (isExpiringSoon) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.warning, size: 14, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text('Expiring soon! Renewal reminder active.', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (c.documentUrl != null && c.documentUrl!.isNotEmpty)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _launchUrl(c.documentUrl!),
                                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                                    label: const Text('View PDF', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      side: const BorderSide(color: AppColors.slate300),
                                    ),
                                  ),
                                ),
                              if (c.documentUrl != null && c.documentUrl!.isNotEmpty)
                                const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (onRequestRenewal != null) onRequestRenewal!();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Renewal requested via GharBook!')),
                                    );
                                  },
                                  icon: const Icon(Icons.autorenew, size: 16),
                                  label: const Text('One-Click Renew', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              if (onDeleteAgreement != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Agreement?'),
                                        content: const Text('Are you sure you want to delete this agreement case? This action cannot be undone.'),
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
                                      onDeleteAgreement!(c.id);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AgreementDetailsSheet extends StatefulWidget {
  final LegalCase caseItem;
  final DateTime startDate;
  final DateTime endDate;
  final Future<void> Function(String) onLaunchUrl;
  final Future<void> Function(String, String, Uint8List)? onUploadDocument;

  const _AgreementDetailsSheet({
    required this.caseItem,
    required this.startDate,
    required this.endDate,
    required this.onLaunchUrl,
    this.onUploadDocument,
  });

  @override
  State<_AgreementDetailsSheet> createState() => _AgreementDetailsSheetState();
}

class _AgreementDetailsSheetState extends State<_AgreementDetailsSheet> {
  bool _isUploading = false;

  Map<String, String> _getDetails(Map<String, dynamic>? detailsMap) {
    if (detailsMap == null) return {};
    return detailsMap.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final details = _getDetails(widget.caseItem.details);
    
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Agreement Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          _buildDetailRow('Status', widget.caseItem.status.name.toUpperCase(), isStatus: true),
          _buildDetailRow('Start Date', widget.startDate.toLocal().toString().split(' ')[0]),
          _buildDetailRow('End Date', widget.endDate.toLocal().toString().split(' ')[0]),
          
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Submitted Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
              child: Column(
                children: details.entries.where((e) => !e.key.contains('date')).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: Text(_formatKey(e.key), style: const TextStyle(color: AppColors.slate500, fontSize: 12))),
                        Expanded(flex: 3, child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          if (widget.caseItem.documentUrl != null && widget.caseItem.documentUrl!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onLaunchUrl(widget.caseItem.documentUrl!),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text('View Agreement Document', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            )
          else if (widget.onUploadDocument != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : () async {
                  setState(() => _isUploading = true);
                  try {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      withData: true,
                    );

                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      if (file.bytes != null) {
                        await widget.onUploadDocument!(widget.caseItem.id, file.name, file.bytes!);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document attached successfully!')));
                        }
                      } else {
                        throw Exception('Could not read file data. Try another file.');
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
                    }
                  } finally {
                    if (mounted) setState(() => _isUploading = false);
                  }
                },
                icon: _isUploading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.upload_file, color: Colors.indigo),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Agreement Document', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.indigo)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }
}
