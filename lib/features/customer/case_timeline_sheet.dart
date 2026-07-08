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
    final tenant = dbService.tenants
        .where((t) => t.id == widget.legalCase.tenantId)
        .firstOrNull;

    // Check missing details
    final List<String> missingDetails = [];
    final uploadedFiles = widget.legalCase.details?['uploaded_files'] as Map<String, dynamic>? ?? {};

    bool isOption3ExistingAgreement = widget.legalCase.details?['is_existing_agreement'] == true;
    
    // For existing agreements, property and tenant selection is still required
    if (widget.legalCase.propertyId == null && widget.legalCase.details?['property_address'] == null) {
      missingDetails.add("Property not selected for this agreement.");
    }
    if (widget.legalCase.tenantId == null && widget.legalCase.details?['tenant_name'] == null) {
      missingDetails.add("Tenant not selected for this agreement.");
    } else if (tenant != null && !isOption3ExistingAgreement) {
      // Only check tenant documents for NEW agreements, not for existing agreements
      bool hasTenantAadhaarDoc = uploadedFiles.keys.any((k) => k.toLowerCase().contains('tenant aadhaar'));
      bool hasTenantPanDoc = uploadedFiles.keys.any((k) => k.toLowerCase().contains('tenant pan'));

      if (tenant.aadhaar.isEmpty && !hasTenantAadhaarDoc) {
        missingDetails.add("Tenant Aadhaar is missing.");
      }
      if (tenant.pan.isEmpty && !hasTenantPanDoc) {
        missingDetails.add("Tenant PAN is missing.");
      }
    }

    // Check document based on service type
    bool isRecordExistingService =
        widget.legalCase.serviceType.toLowerCase().contains("record") ||
        widget.legalCase.serviceType.toLowerCase().contains("existing");
        
    bool hasRentAgreementDoc = uploadedFiles.keys.any((k) => k.toLowerCase().contains('rent agreement'));

    // For Option 3 (Existing Agreement), document upload is not required
    // For other "record" or "existing" service types, document upload is still required
    if (isRecordExistingService &&
        !isOption3ExistingAgreement &&
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
              // Show different UI for existing agreements vs new agreements
              if (widget.legalCase.details?['is_existing_agreement'] == true) ...[
                // For existing agreements: show recorded status with enhanced infographics
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade50,
                        Colors.teal.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Animated checkmark circle
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.teal.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AGREEMENT RECORDED',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Existing Rent Agreement',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats/infographics row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoStat(
                              Icons.calendar_today,
                              'Recorded Date',
                              widget.legalCase.createdAt.split('T')[0],
                              Colors.blue.shade700,
                            ),
                            _buildInfoStat(
                              Icons.business,
                              'Property',
                              widget.legalCase.details?['property_address']?.toString() ?? 'Selected',
                              Colors.purple.shade700,
                            ),
                            _buildInfoStat(
                              Icons.person,
                              'Tenant',
                              widget.legalCase.details?['tenant_name']?.toString() ?? 'Selected',
                              Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This existing rent agreement has been successfully recorded in the system. All details have been saved for future reference and rent tracking.',
                        style: TextStyle(
                          color: AppColors.slate600,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Note: This agreement was already executed and is being recorded for digital management.',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // For new agreements: show the enhanced timeline
                const Text(
                  'Agreement Progress Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track the progress of your new agreement request',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimeline(widget.legalCase.status),
                const SizedBox(height: 24),
              ],
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
      {
        'status': AgreementStatus.newRequest,
        'label': 'Request Received',
        'icon': Icons.description,
        'description': 'Agreement request submitted'
      },
      {
        'status': AgreementStatus.documentsPending,
        'label': 'Document Review',
        'icon': Icons.folder_open,
        'description': 'Documents under review'
      },
      {
        'status': AgreementStatus.draftReady,
        'label': 'Draft Ready',
        'icon': Icons.edit_document,
        'description': 'Draft agreement prepared'
      },
      {
        'status': AgreementStatus.biometricCompleted,
        'label': 'Biometric Verified',
        'icon': Icons.fingerprint,
        'description': 'Biometric verification done'
      },
      {
        'status': AgreementStatus.governmentRegistration,
        'label': 'Govt Registration',
        'icon': Icons.account_balance,
        'description': 'Government registration'
      },
      {
        'status': AgreementStatus.completed,
        'label': 'Completed',
        'icon': Icons.check_circle,
        'description': 'Agreement fully executed'
      },
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
        final isPending = index > currentIndex;
        final label = stages[index]['label'] as String;
        final icon = stages[index]['icon'] as IconData;
        final description = stages[index]['description'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator with icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green.shade100
                      : (isCurrent ? Colors.amber.shade100 : Colors.grey.shade100),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : (isCurrent ? Colors.amber.shade400 : Colors.grey.shade300),
                    width: 2,
                  ),
                  boxShadow: [
                    if (isCurrent)
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: isCompleted
                        ? Colors.green.shade800
                        : (isCurrent ? Colors.amber.shade800 : Colors.grey.shade600),
                  ),
                ),
              ),
              
              // Connecting line for all except last item
              if (index < stages.length - 1)
                Container(
                  width: 2,
                  height: 50,
                  margin: const EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isCompleted ? Colors.green : Colors.grey.shade300,
                        isPending ? Colors.grey.shade300 : Colors.green,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              
              const SizedBox(width: 12),
              
              // Stage content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.amber.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? Colors.amber.shade200 : Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade100
                                  : (isCurrent ? Colors.amber.shade100 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCompleted ? 'COMPLETED' : (isCurrent ? 'CURRENT' : 'PENDING'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.green.shade800
                                    : (isCurrent ? Colors.amber.shade800 : Colors.grey.shade600),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCompleted || isCurrent
                              ? const Color(0xFF0F172A)
                              : AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                      // Show estimated time for current stage
                      if (isCurrent) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Estimated: 2-3 days',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Helper method for creating info stat boxes
  Widget _buildInfoStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.length > 10 ? '${value.substring(0, 10)}...' : value,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}