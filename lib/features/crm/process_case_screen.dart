import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import '../../services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProcessCaseScreen extends StatefulWidget {
  final LegalCase legalCase;

  const ProcessCaseScreen({super.key, required this.legalCase});

  @override
  State<ProcessCaseScreen> createState() => _ProcessCaseScreenState();
}

class _ProcessCaseScreenState extends State<ProcessCaseScreen> {
  late AgreementStatus _currentStatus;
  bool _isUpdating = false;
  String? _documentUrl;

  final List<Map<String, dynamic>> _workflowSteps = [
    {'status': AgreementStatus.newRequest, 'dbValue': 'New', 'title': 'New', 'desc': 'Customer has created a service request.'},
    {'status': AgreementStatus.documentsPending, 'dbValue': 'Documents Pending', 'title': 'Documents Pending', 'desc': 'Waiting for customer/staff to upload required documents.'},
    {'status': AgreementStatus.dataEntry, 'dbValue': 'Data Entry', 'title': 'Data Entry', 'desc': 'Extracting data from documents for the agreement.'},
    {'status': AgreementStatus.verification, 'dbValue': 'Verification', 'title': 'Verification', 'desc': 'Verifying documents and extracted data.'},
    {'status': AgreementStatus.draftReady, 'dbValue': 'Draft Ready', 'title': 'Draft Ready', 'desc': 'The agreement draft has been generated.'},
    {'status': AgreementStatus.clientApproval, 'dbValue': 'Client Approval', 'title': 'Client Approval', 'desc': 'Waiting for the customer to approve the draft.'},
    {'status': AgreementStatus.biometricScheduled, 'dbValue': 'Biometric Scheduled', 'title': 'Biometric Scheduled', 'desc': 'Doorstep biometric appointment is scheduled.'},
    {'status': AgreementStatus.biometricCompleted, 'dbValue': 'Biometric Completed', 'title': 'Biometric Completed', 'desc': 'Doorstep biometric verification is completed.'},
    {'status': AgreementStatus.governmentRegistration, 'dbValue': 'Government Registration', 'title': 'Government Registration', 'desc': 'Submitting to the government portal for registration.'},
    {'status': AgreementStatus.completed, 'dbValue': 'Completed', 'title': 'Completed', 'desc': 'Agreement is registered and case is closed.'},
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.legalCase.status;
    _documentUrl = widget.legalCase.documentUrl;
  }

  int get _currentStepIndex {
    return _workflowSteps.indexWhere((step) => step['status'] == _currentStatus);
  }

  Future<void> _advanceStatus() async {
    final nextIndex = _currentStepIndex + 1;
    if (nextIndex >= _workflowSteps.length) return;

    setState(() => _isUpdating = true);

    try {
      final nextStep = _workflowSteps[nextIndex];
      await context.read<DatabaseService>().updateCaseStatus(
        widget.legalCase.id, 
        nextStep['dbValue'] as String,
      );
      setState(() {
        _currentStatus = nextStep['status'] as AgreementStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Case advanced to ${nextStep['title']}!'), backgroundColor: AppColors.emerald600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _isUpdating = true);
      try {
        await context.read<DatabaseService>().uploadAgreementDocument(
          widget.legalCase.id,
          result.files.single.name,
          result.files.single.bytes!,
        );
        
        // Find the newly updated case from provider to get the new document URL
        final cases = context.read<DatabaseService>().cases;
        final updatedCase = cases.firstWhere((c) => c.id == widget.legalCase.id);
        
        setState(() {
          _documentUrl = updatedCase.documentUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreement uploaded successfully!'), backgroundColor: AppColors.emerald600));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload agreement.'), backgroundColor: Colors.red));
        }
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Process Case Workspace', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CASE ID: ${widget.legalCase.requestId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 4),
                Text(widget.legalCase.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Text('Client: ${widget.legalCase.clientName}', style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Stepper(
              currentStep: _currentStepIndex == -1 ? 0 : _currentStepIndex,
              controlsBuilder: (context, details) {
                return const SizedBox.shrink(); // Hide default buttons
              },
              steps: _workflowSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isActive = index <= _currentStepIndex;
                
                return Step(
                  title: Text(step['title'] as String, style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? const Color(0xFF0F172A) : AppColors.slate400,
                  )),
                  subtitle: Text(step['desc'] as String, style: const TextStyle(fontSize: 11)),
                  content: const SizedBox.shrink(), // No extra content inside steps yet
                  isActive: isActive,
                  state: index < _currentStepIndex ? StepState.complete : (index == _currentStepIndex ? StepState.editing : StepState.indexed),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_documentUrl != null)
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(_documentUrl!), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                label: const Text('View Uploaded Agreement', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              )
            else
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : _uploadDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Agreement PDF'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _currentStepIndex >= _workflowSteps.length - 1 || _isUpdating
                  ? null
                  : _advanceStatus,
              icon: _isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.arrow_forward),
              label: Text(_currentStepIndex >= _workflowSteps.length - 1 ? 'Case Completed' : 'Advance to Next Stage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
