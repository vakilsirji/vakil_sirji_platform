import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import 'package:url_launcher/url_launcher.dart';
import 'case_timeline_sheet.dart';

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

  void _showDetailsSheet(
    BuildContext context,
    LegalCase c,
    DateTime startDate,
    DateTime endDate,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return CaseTimelineSheet(
          legalCase: c,
          startDate: startDate,
          endDate: endDate,
          onUploadDocument: onUploadDocument,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final agreements = cases
        .where((c) => c.serviceType.toLowerCase().contains('agreement'))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: agreements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 60,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No agreements found.',
                    style: TextStyle(color: AppColors.slate500),
                  ),
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
                  final startString = c.details!['existing_start_date']
                      ?.toString();
                  final endString = c.details!['existing_end_date']?.toString();

                  if (startString != null && startString.isNotEmpty) {
                    parsedStart = DateTime.tryParse(startString.trim());
                  }
                  if (endString != null && endString.isNotEmpty) {
                    parsedEnd = DateTime.tryParse(endString.trim());
                  }
                }

                // Fallback to creation date + 330 days if not an existing agreement
                final startDate =
                    parsedStart ??
                    DateTime.tryParse(c.createdAt) ??
                    DateTime.now();
                final endDate =
                    parsedEnd ??
                    startDate.add(const Duration(days: 330)); // ~11 months
                final isExpiringSoon =
                    endDate.difference(DateTime.now()).inDays < 30;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        _showDetailsSheet(context, c, startDate, endDate),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: c.status == AgreementStatus.completed
                                      ? Colors.green.shade50
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: c.status == AgreementStatus.completed
                                        ? Colors.green.shade700
                                        : Colors.amber.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Start: ${startDate.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.event_busy,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'End: ${endDate.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildProgressArrow(c.status),
                          if (isExpiringSoon) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Expiring soon! Renewal reminder active.',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (c.documentUrl != null &&
                                  c.documentUrl!.isNotEmpty)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _launchUrl(c.documentUrl!),
                                    icon: const Icon(
                                      Icons.picture_as_pdf,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'View PDF',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      side: const BorderSide(
                                        color: AppColors.slate300,
                                      ),
                                    ),
                                  ),
                                ),
                              if (isExpiringSoon) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (onRequestRenewal != null)
                                        onRequestRenewal!();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Renewal requested via GharBook!',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.autorenew, size: 16),
                                    label: const Text(
                                      'One-Click Renew',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (onDeleteAgreement != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Agreement?'),
                                        content: const Text(
                                          'Are you sure you want to delete this agreement case? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
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

  Widget _buildProgressArrow(AgreementStatus currentStatus) {
    final stages = [
      {'status': AgreementStatus.newRequest, 'label': 'Request'},
      {'status': AgreementStatus.documentsPending, 'label': 'Docs'},
      {'status': AgreementStatus.draftReady, 'label': 'Draft'},
      {'status': AgreementStatus.biometricCompleted, 'label': 'Biometric'},
      {'status': AgreementStatus.governmentRegistration, 'label': 'Govt Reg'},
      {'status': AgreementStatus.completed, 'label': 'Done'},
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: List.generate(stages.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Arrow connector
            final stageIdx = i ~/ 2;
            final isCompleted = stageIdx < currentIndex;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Colors.green : AppColors.slate300,
                    ),
                  ),
                  Icon(
                    Icons.arrow_right,
                    size: 14,
                    color: isCompleted ? Colors.green : AppColors.slate300,
                  ),
                ],
              ),
            );
          }

          final stageIdx = i ~/ 2;
          final isCompleted = stageIdx < currentIndex;
          final isCurrent = stageIdx == currentIndex;
          final label = stages[stageIdx]['label'] as String;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : (isCurrent ? Colors.amber.shade700 : Colors.transparent),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : (isCurrent ? Colors.amber.shade700 : AppColors.slate300),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF0F172A)
                      : AppColors.slate400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
