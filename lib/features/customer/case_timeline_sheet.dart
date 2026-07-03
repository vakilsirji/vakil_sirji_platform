import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import '../../services/database_service.dart';

class CaseTimelineSheet extends StatelessWidget {
  final LegalCase legalCase;

  const CaseTimelineSheet({super.key, required this.legalCase});

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final property = dbService.properties.where((p) => p.id == legalCase.propertyId).firstOrNull;
    final tenant = dbService.tenants.where((t) => t.id == legalCase.tenantId).firstOrNull;

    // Check missing details
    final List<String> missingDetails = [];
    
    if (legalCase.propertyId == null) {
      missingDetails.add("Property not selected for this agreement.");
    }
    if (legalCase.tenantId == null) {
      missingDetails.add("Tenant not selected for this agreement.");
    } else if (tenant != null) {
      if (tenant.aadhaar.isEmpty) missingDetails.add("Tenant Aadhaar is missing.");
      if (tenant.pan.isEmpty) missingDetails.add("Tenant PAN is missing.");
      if (tenant.currentAddress.isEmpty) missingDetails.add("Tenant Address is missing.");
    }

    // Check document based on service type
    bool isRecordExisting = legalCase.serviceType.toLowerCase().contains("record") || legalCase.serviceType.toLowerCase().contains("existing");
    if (isRecordExisting && (legalCase.documentUrl == null || legalCase.documentUrl!.isEmpty)) {
      missingDetails.add("Agreement PDF document not uploaded.");
    }

    bool isComplete = missingDetails.isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Agreement Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(legalCase.title, style: const TextStyle(color: AppColors.slate500, fontSize: 14)),
          const Divider(height: 32),
          
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
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text('Action Required', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Please complete the following details to proceed:', style: TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...missingDetails.map((msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ] else ...[
            // Show timeline
            _buildTimeline(legalCase.status),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimeline(AgreementStatus currentStatus) {
    final stages = [
      {'status': AgreementStatus.newRequest, 'label': 'Request Received'},
      {'status': AgreementStatus.documentsPending, 'label': 'Document Review'},
      {'status': AgreementStatus.draftReady, 'label': 'Draft Ready'},
      {'status': AgreementStatus.biometricCompleted, 'label': 'Biometric Verified'},
      {'status': AgreementStatus.governmentRegistration, 'label': 'Govt Registration'},
      {'status': AgreementStatus.completed, 'label': 'Completed'},
    ];

    int currentIndex = stages.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) {
      if (currentStatus == AgreementStatus.dataEntry || currentStatus == AgreementStatus.verification) {
        currentIndex = 1; 
      } else if (currentStatus == AgreementStatus.clientApproval || currentStatus == AgreementStatus.biometricScheduled) {
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
                    color: isCompleted ? Colors.green : (isCurrent ? Colors.amber : Colors.grey.shade300),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : (isCurrent ? Icons.circle : Icons.circle_outlined),
                    size: 14,
                    color: isCompleted ? Colors.white : (isCurrent ? Colors.white : Colors.grey.shade500),
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
                    color: isCompleted || isCurrent ? const Color(0xFF0F172A) : AppColors.slate400,
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
