import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../../models/user_profile.dart';
import 'package:file_picker/file_picker.dart';

class CreateRequestScreen extends StatefulWidget {
  final List<Property> properties;
  final List<Tenant> tenants;
  final UserProfile currentUser;
  final void Function(String serviceType, String propertyId, String tenantId, [Map<String, dynamic>? manualDetails]) onSubmit;
  final bool initialIsExisting;

  const CreateRequestScreen({
    super.key,
    required this.properties,
    required this.tenants,
    required this.currentUser,
    required this.onSubmit,
    this.initialIsExisting = false,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  int _currentStep = 0;
  String _selectedService = 'Rent Agreement';
  late int _selectedOption;
  String? _selectedPropertyId;
  String? _selectedTenantId;
  int _coOwnerCount = 0;
  int _coTenantCount = 0;

  final List<String> _services = [
    'Rent Agreement',
    'Agreement Renewal',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialIsExisting ? 3 : 2;
    if (widget.properties.isNotEmpty) _selectedPropertyId = widget.properties.first.id;
    if (widget.tenants.isNotEmpty) _selectedTenantId = widget.tenants.first.id;

    // Auto-fill Owner details
    _getCtrl('owner_name').text = widget.currentUser.name;
    _getCtrl('owner_mobile').text = widget.currentUser.mobile;
    _getCtrl('owner_email').text = widget.currentUser.email;
    if (widget.currentUser.address != null) _getCtrl('owner_address').text = widget.currentUser.address!;
    if (widget.currentUser.aadhaar != null) _getCtrl('owner_aadhaar').text = widget.currentUser.aadhaar!;
    if (widget.currentUser.pan != null) _getCtrl('owner_pan').text = widget.currentUser.pan!;
  }

  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, String> _uploadedFiles = {};

  Future<void> _pickFile(String label, {bool allowMultiple = false}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: allowMultiple,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (allowMultiple) {
          _uploadedFiles[label] = result.files.map((e) => e.name).join(', ');
        } else {
          _uploadedFiles[label] = result.files.first.name;
        }
      });
    }
  }

  TextEditingController _getCtrl(String key) {
    _ctrls.putIfAbsent(key, () => TextEditingController());
    return _ctrls[key]!;
  }

  void _submit() {
    Map<String, dynamic>? manualDetails = {};
    
    if (_selectedOption == 1 || _selectedOption == 3 || _selectedOption == 2) {
      _ctrls.forEach((key, ctrl) {
        manualDetails![key] = ctrl.text;
      });
      if (_selectedOption == 3) {
        manualDetails['is_existing_agreement'] = true;
      }
    }
    
    if (_selectedOption == 2) {
      manualDetails['uploaded_files'] = _uploadedFiles;
    }

    // Attach uploaded files to all options if any exist
    if (_uploadedFiles.isNotEmpty && _selectedOption != 2) {
      manualDetails['uploaded_files'] = _uploadedFiles;
    }

    widget.onSubmit(_selectedService, _selectedPropertyId ?? '', _selectedTenantId ?? '', manualDetails);
    Navigator.pop(context);
  }

  Future<void> _selectDate(String ctrlKey) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _getCtrl(ctrlKey).text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _calculateEndDate();
      });
    }
  }

  void _calculateEndDate() {
    final startText = _getCtrl('existing_start_date').text;
    final durationText = _getCtrl('existing_duration_months').text;
    if (startText.isNotEmpty && durationText.isNotEmpty) {
      try {
        final startDate = DateTime.parse(startText);
        final months = int.parse(durationText);
        final endDate = DateTime(startDate.year, startDate.month + months, startDate.day);
        _getCtrl('existing_end_date').text = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      } catch (e) {
        // Ignored
      }
    }
  }

  @override
  void dispose() {
    for (var ctrl in _ctrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<Step> get _steps {
    List<Step> steps = [];
    
    // STEP 0: Select Service & Option
    steps.add(Step(
      title: const Text('Service & Method', style: TextStyle(fontWeight: FontWeight.bold)),
      isActive: _currentStep >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Type', style: TextStyle(color: AppColors.slate600, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedService,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _selectedService = val!),
          ),
          if (_selectedOption != 3) ...[
            const SizedBox(height: 24),
            const Text('How would you like to proceed?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() { _selectedOption = 1; _currentStep = 0; }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedOption == 1 ? Colors.amber.shade700 : AppColors.slate200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedOption == 1 ? Colors.amber.shade50 : Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_document),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Option 1: Fill details yourself', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Manually type in all owner, tenant, and witness details.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() { _selectedOption = 2; _currentStep = 0; }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedOption == 2 ? const Color(0xFF0F172A) : AppColors.slate200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedOption == 2 ? AppColors.slate50 : Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF0F172A)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Option 2: We do it for you', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                child: const Text('RECOMMENDED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const Text('Just upload documents. GharBook prepares everything.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            const Text('You have selected to record an existing agreement. Proceed to the next step to enter the details.', style: TextStyle(color: AppColors.slate500)),
          ],
        ],
      ),
    ));

    if (_selectedOption == 1) {
      // Manual Entry Steps
      steps.add(Step(
        title: const Text('Owner & Tenant Details', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Owner Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const Text('Auto-filled (Editable)', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
              ]
            ),
            const SizedBox(height: 8),
            _buildTextField('owner_name', 'Full Name'),
            Row(
              children: [
                Expanded(child: _buildTextField('owner_age', 'Age')),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField('owner_mobile', 'Mobile')),
              ],
            ),
            _buildTextField('owner_email', 'Email'),
            _buildTextField('owner_aadhaar', 'Aadhaar Number'),
            _buildTextField('owner_pan', 'PAN Number'),
            _buildTextField('owner_address', 'Current Address', maxLines: 2),
            for (int i = 1; i <= _coOwnerCount; i++) ...[
              const Divider(height: 16),
              Text('Co-Owner $i Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              _buildTextField('co_owner_${i}_name', 'Full Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('co_owner_${i}_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildTextField('co_owner_${i}_mobile', 'Mobile')),
                ],
              ),
              _buildTextField('co_owner_${i}_aadhaar', 'Aadhaar Number'),
              _buildTextField('co_owner_${i}_pan', 'PAN Number'),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _coOwnerCount++), 
              icon: const Icon(Icons.add), 
              label: const Text('Add Co-Owner')
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tenant Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const Text('Auto-fill from list:', style: TextStyle(fontSize: 10, color: AppColors.slate500)),
              ]
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: null,
              hint: const Text('Add New Tenant'),
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              items: [
                const DropdownMenuItem(value: null, child: Text('Add New Tenant', style: TextStyle(color: Colors.blue))),
                ...widget.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
              ],
              onChanged: (val) {
                if (val == null) {
                  _getCtrl('tenant_name').clear();
                  _getCtrl('tenant_mobile').clear();
                  _getCtrl('tenant_email').clear();
                  _getCtrl('tenant_aadhaar').clear();
                  _getCtrl('tenant_pan').clear();
                  _getCtrl('tenant_address').clear();
                  _getCtrl('tenant_perm_address').clear();
                } else {
                  final tenant = widget.tenants.firstWhere((t) => t.id == val);
                  _getCtrl('tenant_name').text = tenant.name;
                  _getCtrl('tenant_mobile').text = tenant.mobile;
                  if (tenant.email != null) _getCtrl('tenant_email').text = tenant.email!;
                  if (tenant.aadhaar != null) _getCtrl('tenant_aadhaar').text = tenant.aadhaar!;
                  if (tenant.pan != null) _getCtrl('tenant_pan').text = tenant.pan!;
                  if (tenant.currentAddress != null) _getCtrl('tenant_address').text = tenant.currentAddress!;
                  if (tenant.permanentAddress != null) _getCtrl('tenant_perm_address').text = tenant.permanentAddress!;
                }
              },
            ),
            const SizedBox(height: 12),
            _buildTextField('tenant_name', 'Full Name'),
            Row(
              children: [
                Expanded(child: _buildTextField('tenant_age', 'Age')),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField('tenant_mobile', 'Mobile')),
              ],
            ),
            _buildTextField('tenant_email', 'Email'),
            _buildTextField('tenant_aadhaar', 'Aadhaar Number'),
            _buildTextField('tenant_pan', 'PAN Number'),
            _buildTextField('tenant_address', 'Current Address', maxLines: 2),
            _buildTextField('tenant_perm_address', 'Permanent Address', maxLines: 2),
            for (int i = 1; i <= _coTenantCount; i++) ...[
              const Divider(height: 16),
              Text('Co-Tenant $i Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              _buildTextField('co_tenant_${i}_name', 'Full Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('co_tenant_${i}_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildTextField('co_tenant_${i}_mobile', 'Mobile')),
                ],
              ),
              _buildTextField('co_tenant_${i}_aadhaar', 'Aadhaar Number'),
              _buildTextField('co_tenant_${i}_pan', 'PAN Number'),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _coTenantCount++), 
              icon: const Icon(Icons.add), 
              label: const Text('Add Co-Tenant')
            ),
          ],
        ),
      ));
      
      steps.add(Step(
        title: const Text('Witness Details', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Witness 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            _buildTextField('w1_name', 'Name'),
            Row(
              children: [
                Expanded(child: _buildTextField('w1_age', 'Age')),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField('w1_mobile', 'Mobile')),
              ],
            ),
            _buildTextField('w1_aadhaar', 'Aadhaar Number'),
            _buildTextField('w1_address', 'Address', maxLines: 2),
            const Divider(height: 32),
            const Text('Witness 2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            _buildTextField('w2_name', 'Name'),
            Row(
              children: [
                Expanded(child: _buildTextField('w2_age', 'Age')),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField('w2_mobile', 'Mobile')),
              ],
            ),
            _buildTextField('w2_aadhaar', 'Aadhaar Number'),
            _buildTextField('w2_address', 'Address', maxLines: 2),
          ],
        ),
      ));
    } else if (_selectedOption == 3) {
      // Existing Agreement Steps
      steps.add(Step(
        title: const Text('Select Property & Tenant', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Property', style: TextStyle(color: AppColors.slate600, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedPropertyId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (val) => setState(() => _selectedPropertyId = val),
            ),
            const SizedBox(height: 16),
            const Text('Tenant (Required)', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTenantId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (val) => setState(() => _selectedTenantId = val),
            ),
          ],
        ),
      ));

      steps.add(Step(
        title: const Text('Agreement Details', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _selectDate('existing_start_date'),
              child: IgnorePointer(
                child: _buildTextField('existing_start_date', 'Start Date (YYYY-MM-DD)'),
              ),
            ),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _calculateEndDate();
              },
              child: _buildTextField('existing_duration_months', 'Duration (Months)'),
            ),
            IgnorePointer(
              child: _buildTextField('existing_end_date', 'Calculated End Date'),
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('existing_rent_amount', 'Rent Amount (₹)')),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('existing_deposit_amount', 'Deposit (₹)')),
              ],
            ),
            _buildTextField('existing_rent_pay_date', 'Rent Pay Date (e.g., 1, 5)'),
          ],
        ),
      ));
    } else {
       // Delegated Step (Link to Property/Tenant)
       steps.add(Step(
         title: const Text('Select Property', style: TextStyle(fontWeight: FontWeight.bold)),
         isActive: _currentStep >= 1,
         content: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('Property', style: TextStyle(color: AppColors.slate600, fontSize: 12)),
             const SizedBox(height: 8),
             DropdownButtonFormField<String>(
               value: _selectedPropertyId,
               decoration: const InputDecoration(border: OutlineInputBorder()),
               items: widget.properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
               onChanged: (val) => setState(() => _selectedPropertyId = val),
             ),
             const SizedBox(height: 16),
             const Text('Tenant (Optional)', style: TextStyle(color: AppColors.slate600, fontSize: 12)),
             const SizedBox(height: 8),
             DropdownButtonFormField<String>(
               value: _selectedTenantId,
               decoration: const InputDecoration(border: OutlineInputBorder()),
               items: widget.tenants.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
               onChanged: (val) => setState(() => _selectedTenantId = val),
             ),
           ],
         ),
       ));
    }

    if (_selectedOption == 1 || _selectedOption == 2) {
      steps.add(Step(
        title: const Text('Agreement Period', style: TextStyle(fontWeight: FontWeight.bold)),
        isActive: _currentStep >= steps.length,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _selectDate('existing_start_date'),
              child: IgnorePointer(
                child: _buildTextField('existing_start_date', 'Start Date (YYYY-MM-DD)'),
              ),
            ),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _calculateEndDate();
              },
              child: _buildTextField('existing_duration_months', 'Duration (Months)'),
            ),
            IgnorePointer(
              child: _buildTextField('existing_end_date', 'Calculated End Date'),
            ),
          ],
        ),
      ));
    }

    // Common Steps (Documents and Review)
    steps.add(Step(
      title: const Text('Upload Documents', style: TextStyle(fontWeight: FontWeight.bold)),
      isActive: _currentStep >= steps.length,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedOption == 3) ...[
            const Text('Upload your existing rent agreement (Optional).', style: TextStyle(color: AppColors.slate600)),
            const SizedBox(height: 24),
            _buildUploadButton('Rent Agreement PDF'),
          ] else ...[
            const Text('Enter names and upload documents below.', style: TextStyle(color: AppColors.slate600)),
            const SizedBox(height: 24),
            
            const Text('Owner Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField('owner_name', 'Owner Name'),
            _buildUploadButton('Owner Aadhaar', allowMultiple: false),
            _buildUploadButton('Owner PAN', allowMultiple: false),
            for (int i = 1; i <= _coOwnerCount; i++) ...[
              const Divider(height: 16),
              Text('Co-Owner $i', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('co_owner_${i}_name', 'Co-Owner $i Name'),
              _buildUploadButton('Co-Owner $i Aadhaar', allowMultiple: false),
              _buildUploadButton('Co-Owner $i PAN', allowMultiple: false),
            ],
            TextButton.icon(onPressed: () => setState(() => _coOwnerCount++), icon: const Icon(Icons.add), label: const Text('Add Co-Owner')),
            const Divider(height: 32),
            
            const Text('Tenant Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField('tenant_name', 'Tenant Name'),
            _buildUploadButton('Tenant Aadhaar', allowMultiple: false),
            _buildUploadButton('Tenant PAN', allowMultiple: false),
            for (int i = 1; i <= _coTenantCount; i++) ...[
              const Divider(height: 16),
              Text('Co-Tenant $i', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('co_tenant_${i}_name', 'Co-Tenant $i Name'),
              _buildUploadButton('Co-Tenant $i Aadhaar', allowMultiple: false),
              _buildUploadButton('Co-Tenant $i PAN', allowMultiple: false),
            ],
            TextButton.icon(onPressed: () => setState(() => _coTenantCount++), icon: const Icon(Icons.add), label: const Text('Add Co-Tenant')),
            const Divider(height: 32),
            
            _buildUploadButton('Witness 1 Aadhaar'),
            _buildUploadButton('Witness 2 Aadhaar'),
            const Divider(height: 32),
            _buildUploadButton('Electricity Bill'),
          ],
        ],
      ),
    ));

    steps.add(Step(
      title: const Text('Review & Submit', style: TextStyle(fontWeight: FontWeight.bold)),
      isActive: _currentStep >= steps.length,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please verify the details below before submitting.'),
          const SizedBox(height: 16),
          _buildReviewItem('Service', _selectedService),
          _buildReviewItem('Method', _selectedOption == 1 ? 'Manual Entry' : (_selectedOption == 3 ? 'Existing Agreement' : 'GharBook Prepares')),
          _buildReviewItem('Documents', _selectedOption == 3 ? 'Not Required' : 'Uploaded'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedOption == 3 ? Colors.green.shade50 : Colors.amber.shade50, 
              borderRadius: BorderRadius.circular(8)
            ),
            child: Row(
              children: [
                Icon(_selectedOption == 3 ? Icons.check_circle_outline : Icons.info_outline, color: _selectedOption == 3 ? Colors.green : Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedOption == 3 
                        ? 'Once submitted, these details will instantly activate the Rent Hub for this property.' 
                        : 'Once submitted, our team will verify the documents and process your request within 24 hours.', 
                    style: const TextStyle(fontSize: 12)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    return steps;
  }

  Widget _buildTextField(String key, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _getCtrl(key),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildUploadButton(String label, {bool allowMultiple = false}) {
    final uploaded = _uploadedFiles.containsKey(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ElevatedButton.icon(
            onPressed: () => _pickFile(label, allowMultiple: allowMultiple),
            icon: Icon(uploaded ? Icons.check_circle : Icons.upload_file, size: 16, color: uploaded ? Colors.green : Colors.grey),
            label: Text(uploaded ? 'Uploaded' : 'Select File', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: uploaded ? Colors.green.shade50 : AppColors.slate100,
              foregroundColor: uploaded ? Colors.green.shade700 : AppColors.slate700,
              elevation: 0,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepsList = _steps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service Request', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stepper(
        key: ValueKey(_selectedOption),
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 1 && _selectedOption == 3) {
            if (_selectedPropertyId == null || _selectedTenantId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select both Property and Tenant to activate Rent Hub.')),
              );
              return;
            }
          }
          if (_currentStep < stepsList.length - 1) {
            setState(() => _currentStep += 1);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A), 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    child: Text(_currentStep == stepsList.length - 1 ? 'Submit Request' : 'Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(_currentStep > 0 ? 'Back' : 'Cancel'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: stepsList,
      ),
    );
  }
}
