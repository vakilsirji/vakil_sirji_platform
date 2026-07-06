import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import '../../services/database_service.dart';

class CaseTimelineSheet extends StatefulWidget {
  final LegalCase legalCase;
  final DateTime? startDate;
  final DateTime? endDate;
  final Future<void> Function(String, String, Uint8List)? onUploadDocument;

  const CaseTimelineSheet({
    super.key,
    required this.legalCase,
    this.startDate,
    this.endDate,
    this.onUploadDocument,
  });

  @override
  State<CaseTimelineSheet> createState() => _CaseTimelineSheetState();
}

class _CaseTimelineSheetState extends State<CaseTimelineSheet> {
  bool _isUploading = false;

  Map<String, String> _getDetails(Map<String, dynamic>? detailsMap) {
    if (detailsMap == null) return {};
    return detailsMap.map((key, value) => MapEntry(key, value.toString()));
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final property = dbService.properties
        .where((p) => p.id == widget.legalCase.propertyId)
        .firstOrNull;
    final tenant = dbService.tenants
        .where((t) => t.id == widget.legalCase.tenantId)
        .firstOrNull;

    // Check missing details
    final List<String> missingDetails = [];
    final uploadedFiles = widget.legalCase.details?['uploaded_files'] as Map<String, dynamic>? ?? {};

    if (widget.legalCase.propertyId == null && widget.legalCase.details?['property_address'] == null) {
      missingDetails.add("Property not selected for this agreement.");
    }
    if (widget.legalCase.tenantId == null && widget.legalCase.details?['tenant_name'] == null) {
      missingDetails.add("Tenant not selected for this agreement.");
    } else if (tenant != null) {
      bool hasTenantAadhaarDoc = uploadedFiles.keys.any((k) => k.toLowerCase().contains('tenant aadhaar'));
      bool hasTenantPanDoc = uploadedFiles.keys.any((k) => k.toLowerCase().contains('tenant pan'));

      if (tenant.aadhaar.isEmpty && !hasTenantAadhaarDoc)
        missingDetails.add("Tenant Aadhaar is missing.");
      if (tenant.pan.isEmpty && !hasTenantPanDoc) 
        missingDetails.add("Tenant PAN is missing.");
    }

    // Check document based on service type
    bool isRecordExisting =
        widget.legalCase.serviceType.toLowerCase().contains("record") ||
        widget.legalCase.serviceType.toLowerCase().contains("existing");
        
    bool hasRentAgreementDoc = uploadedFiles.keys.any((k) => k.toLowerCase().contains('rent agreement'));

    if (isRecordExisting &&
        (widget.legalCase.documentUrl == null || widget.legalCase.documentUrl!.isEmpty) &&
        !hasRentAgreementDoc) {
      missingDetails.add("Agreement PDF document not uploaded.");
    }

    bool isComplete = missingDetails.isEmpty;
    final details = _getDetails(widget.legalCase.details);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agreement Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.legalCase.title,
              style: const TextStyle(color: AppColors.slate500, fontSize: 14),
            ),
            const Divider(height: 32),

            if (widget.startDate != null && widget.endDate != null) ...[
              _buildDetailRow(
                'Start Date',
                widget.startDate!.toLocal().toString().split(' ')[0],
              ),
              _buildDetailRow(
                'End Date',
                widget.endDate!.toLocal().toString().split(' ')[0],
              ),
              const SizedBox(height: 16),
            ],

            if (details.isNotEmpty) ...[
              const Text(
                'Submitted Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  children: details.entries
                      .where((e) => !e.key.contains('date'))
                      .map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatKey(e.key),
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (!isComplete) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Action Required',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please complete the following details to proceed:',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ...missingDetails.map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                msg,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Show timeline
              _buildTimeline(widget.legalCase.status),
              const SizedBox(height: 24),
            ],

            if (widget.legalCase.documentUrl != null &&
                widget.legalCase.documentUrl!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(widget.legalCase.documentUrl!),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'View Agreement Document',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (widget.legalCase.status == AgreementStatus.clientApproval ||
                  widget.legalCase.status == AgreementStatus.draftReady) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await context.read<DatabaseService>().updateCaseStatus(
                          widget.legalCase.id,
                          'Biometric Scheduled',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Draft Approved! Admin has been notified.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to approve draft.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Approve Draft & Proceed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ]
            else if (widget.onUploadDocument != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () async {
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
                                await widget.onUploadDocument!(
                                  widget.legalCase.id,
                                  file.name,
                                  file.bytes!,
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Document attached successfully!',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                throw Exception(
                                  'Could not read file data. Try another file.',
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUploading = false);
                          }
                        },
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file, color: Colors.indigo),
                  label: Text(
                    _isUploading ? 'Uploading...' : 'Upload Agreement Document',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.slate500, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(AgreementStatus currentStatus) {
    final stages = [
      {'status': AgreementStatus.newRequest, 'label': 'Request Received'},
      {'status': AgreementStatus.documentsPending, 'label': 'Document Review'},
      {'status': AgreementStatus.draftReady, 'label': 'Draft Ready'},
      {
        'status': AgreementStatus.biometricCompleted,
        'label': 'Biometric Verified',
      },
      {
        'status': AgreementStatus.governmentRegistration,
        'label': 'Govt Registration',
      },
      {'status': AgreementStatus.completed, 'label': 'Completed'},
    ];

    int currentIndex = stages.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) {
      if (currentStatus == AgreementStatus.dataEntry ||
          currentStatus == AgreementStatus.verification) {
        currentIndex = 1;
      } else if (currentStatus == AgreementStatus.clientApproval ||
          currentStatus == AgreementStatus.biometricScheduled) {
        currentIndex = 2;
      } else {
        currentIndex = 0;
      }
    }

    return Column(
      children: List.generate(stages.length, (index) {
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final label = stages[index]['label'] as String;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : (isCurrent ? Colors.amber : Colors.grey.shade300),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : (isCurrent ? Icons.circle : Icons.circle_outlined),
                    size: 14,
                    color: isCompleted
                        ? Colors.white
                        : (isCurrent ? Colors.white : Colors.grey.shade500),
                  ),
                ),
                if (index < stages.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted || isCurrent
                        ? const Color(0xFF0F172A)
                        : AppColors.slate400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
