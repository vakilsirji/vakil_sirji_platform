import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/legal_case.dart';
import '../../services/database_service.dart';
import 'package:flutter/services.dart';
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
    {
      'status': AgreementStatus.newRequest,
      'dbValue': 'New',
      'title': 'New',
      'desc': 'Customer has created a service request.',
    },
    {
      'status': AgreementStatus.documentsPending,
      'dbValue': 'Documents Pending',
      'title': 'Documents Pending',
      'desc': 'Waiting for customer/staff to upload required documents.',
    },
    {
      'status': AgreementStatus.dataEntry,
      'dbValue': 'Data Entry',
      'title': 'Data Entry',
      'desc': 'Extracting data from documents for the agreement.',
    },
    {
      'status': AgreementStatus.verification,
      'dbValue': 'Verification',
      'title': 'Verification',
      'desc': 'Verifying documents and extracted data.',
    },
    {
      'status': AgreementStatus.draftReady,
      'dbValue': 'Draft Ready',
      'title': 'Draft Ready',
      'desc': 'The agreement draft has been generated.',
    },
    {
      'status': AgreementStatus.clientApproval,
      'dbValue': 'Client Approval',
      'title': 'Client Approval',
      'desc': 'Waiting for the customer to approve the draft.',
    },
    {
      'status': AgreementStatus.biometricScheduled,
      'dbValue': 'Biometric Scheduled',
      'title': 'Biometric Scheduled',
      'desc': 'Doorstep biometric appointment is scheduled.',
    },
    {
      'status': AgreementStatus.biometricCompleted,
      'dbValue': 'Biometric Completed',
      'title': 'Biometric Completed',
      'desc': 'Doorstep biometric verification is completed.',
    },
    {
      'status': AgreementStatus.governmentRegistration,
      'dbValue': 'Government Registration',
      'title': 'Government Registration',
      'desc': 'Submitting to the government portal for registration.',
    },
    {
      'status': AgreementStatus.completed,
      'dbValue': 'Completed',
      'title': 'Completed',
      'desc': 'Agreement is registered and case is closed.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.legalCase.status;
    _documentUrl = widget.legalCase.documentUrl;
  }

  int get _currentStepIndex {
    return _workflowSteps.indexWhere(
      (step) => step['status'] == _currentStatus,
    );
  }

  String _formatKey(String key) {
    if (key.isEmpty) return key;
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
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
          SnackBar(
            content: Text('Case advanced to ${nextStep['title']}!'),
            backgroundColor: AppColors.emerald600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
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
        final updatedCase = cases.firstWhere(
          (c) => c.id == widget.legalCase.id,
        );

        setState(() {
          _documentUrl = updatedCase.documentUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agreement uploaded successfully!'),
              backgroundColor: AppColors.emerald600,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload agreement.'),
              backgroundColor: Colors.red,
            ),
          );
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
        title: const Text(
          'Process Case Workspace',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CASE ID: ${widget.legalCase.requestId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.legalCase.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Client: ${widget.legalCase.clientName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                    ),
                  ),
                  if (widget.legalCase.details != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Form Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...() {
                      int getSortWeight(String key) {
                        int groupWeight = 900;
                        if (key.startsWith('property') || key.startsWith('prop_')) groupWeight = 100;
                        else if (key.startsWith('owner') || key.startsWith('co_owner')) groupWeight = 200;
                        else if (key.startsWith('tenant') || key.startsWith('co_tenant')) groupWeight = 300;
                        else if (key.startsWith('w1_')) groupWeight = 400;
                        else if (key.startsWith('w2_')) groupWeight = 500;
                        else if (key.contains('rent') || key.contains('deposit') || key.contains('date') || key.contains('duration')) groupWeight = 600;

                        int fieldWeight = 99;
                        if (key.contains('name')) fieldWeight = 1;
                        else if (key.contains('address')) fieldWeight = 2;
                        else if (key.contains('pan')) fieldWeight = 3;
                        else if (key.contains('age')) fieldWeight = 4;
                        else if (key.contains('mobile')) fieldWeight = 5;

                        return groupWeight + fieldWeight;
                      }

                      final db = context.read<DatabaseService>();
                      final augmentedDetails = Map<String, dynamic>.from(widget.legalCase.details ?? {});

                      if (widget.legalCase.propertyId != null) {
                        try {
                          final p = db.properties.firstWhere((p) => p.id == widget.legalCase.propertyId);
                          augmentedDetails.putIfAbsent('property_address', () => p.address);
                          augmentedDetails.putIfAbsent('property_city', () => p.city);
                          augmentedDetails.putIfAbsent('property_state', () => p.state);
                          augmentedDetails.putIfAbsent('property_pincode', () => p.pinCode);
                          if (p.rentAmount > 0) augmentedDetails.putIfAbsent('rent_amount', () => p.rentAmount.toString());
                          if (p.depositAmount > 0) augmentedDetails.putIfAbsent('deposit_amount', () => p.depositAmount.toString());
                          
                          try {
                            final c = db.clients.firstWhere((c) => c.id == p.ownerId);
                            augmentedDetails.putIfAbsent('owner_name', () => c.name);
                            augmentedDetails.putIfAbsent('owner_mobile', () => c.mobile);
                          } catch (_) {}
                        } catch (_) {}
                      }

                      if (widget.legalCase.tenantId != null) {
                        try {
                          final t = db.tenants.firstWhere((t) => t.id == widget.legalCase.tenantId);
                          augmentedDetails.putIfAbsent('tenant_name', () => t.name);
                          augmentedDetails.putIfAbsent('tenant_mobile', () => t.mobile);
                          if (t.email.isNotEmpty) augmentedDetails.putIfAbsent('tenant_email', () => t.email);
                          if (t.pan.isNotEmpty) augmentedDetails.putIfAbsent('tenant_pan', () => t.pan);
                          if (t.aadhaar.isNotEmpty) augmentedDetails.putIfAbsent('tenant_aadhaar', () => t.aadhaar);
                        } catch (_) {}
                      }

                      final entries = augmentedDetails.entries
                          .where((e) =>
                              e.key != 'uploaded_files' &&
                              e.key != 'property_id' &&
                              e.key != 'tenant_id' &&
                              e.key != 'is_existing_agreement' &&
                              e.value.toString().isNotEmpty)
                          .toList()
                        ..sort((a, b) {
                          final wA = getSortWeight(a.key);
                          final wB = getSortWeight(b.key);
                          if (wA != wB) return wA.compareTo(wB);
                          return a.key.compareTo(b.key);
                        });

                      return entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  '${_formatKey(e.key)}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: SelectableText(
                                        e.value.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: e.value.toString()));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Copied ${_formatKey(e.key)} to clipboard'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: Icon(Icons.copy, size: 14, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }(),
                  ],
                  if (widget.legalCase.details != null &&
                      widget.legalCase.details!['uploaded_files'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Uploaded Documents:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(widget.legalCase.details!['uploaded_files'] as Map)
                        .entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        const Icon(
                                          Icons.description,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 150,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.picture_as_pdf,
                                              size: 64,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          e.value.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final urlString = e.value.toString();
                                            if (!urlString.startsWith('http')) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('This is an old mock document. Create a new case to view real uploads!'),
                                                    backgroundColor: Colors.amber,
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                            
                                            final uri = Uri.parse(urlString);
                                            try {
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Could not open document.')),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.open_in_new),
                                          label: const Text('View Original Document'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attachment,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${e.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.value.toString(),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ],
              ),
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
                  title: Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF0F172A)
                          : AppColors.slate400,
                    ),
                  ),
                  subtitle: Text(
                    step['desc'] as String,
                    style: const TextStyle(fontSize: 11),
                  ),
                  content:
                      const SizedBox.shrink(), // No extra content inside steps yet
                  isActive: isActive,
                  state: index < _currentStepIndex
                      ? StepState.complete
                      : (index == _currentStepIndex
                            ? StepState.editing
                            : StepState.indexed),
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
                onPressed: () => launchUrl(
                  Uri.parse(_documentUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                label: const Text(
                  'View Uploaded Agreement',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : _uploadDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Agreement PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _currentStepIndex >= _workflowSteps.length - 1 || _isUpdating
                  ? null
                  : _advanceStatus,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(
                _currentStepIndex >= _workflowSteps.length - 1
                    ? 'Case Completed'
                    : 'Advance to Next Stage',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
