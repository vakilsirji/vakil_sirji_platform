import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'overview_page.dart';

class CreateRequestScreen extends StatefulWidget {
  final List<Property> properties;
  final List<Tenant> tenants;
  final UserProfile currentUser;
  final void Function(
    String serviceType,
    String propertyId,
    String tenantId, [
    Map<String, dynamic>? manualDetails,
  ])
  onSubmit;
  final bool initialIsExisting;
  final String? initialPropertyId;
  final String? initialTenantId;

  const CreateRequestScreen({
    super.key,
    required this.properties,
    required this.tenants,
    required this.currentUser,
    required this.onSubmit,
    this.initialIsExisting = false,
    this.initialPropertyId,
    this.initialTenantId,
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
  List<String> _selectedCoTenantIds = [];
  int _coOwnerCount = 0;
  int _coTenantCount = 0;
  late List<Tenant> _tenants;
  bool _isManualPropertyEntry = false;

  final List<String> _services = ['Rent Agreement', 'Agreement Renewal'];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialIsExisting ? 3 : 2;
    _tenants = List<Tenant>.from(widget.tenants);
    if (widget.properties.isNotEmpty) {
      _selectedPropertyId = widget.properties.first.id;
      _autoFillFromProperty(widget.properties.first);
    } else {
      _isManualPropertyEntry = true;
    }
    if (_tenants.isNotEmpty) _selectedTenantId = _tenants.first.id;

    // Auto-fill Owner details
    _getCtrl('owner_name').text = widget.currentUser.name;
    _getCtrl('owner_mobile').text = widget.currentUser.mobile;
    _getCtrl('owner_email').text = widget.currentUser.email;
    if (widget.currentUser.address != null)
      _getCtrl('owner_address').text = widget.currentUser.address!;
    if (widget.currentUser.aadhaar != null)
      _getCtrl('owner_aadhaar').text = widget.currentUser.aadhaar!;
    if (widget.currentUser.pan != null)
      _getCtrl('owner_pan').text = widget.currentUser.pan!;
  }

  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, String> _uploadedFiles = {};

  bool _isUploading = false;

  Future<void> _pickFile(String label, {bool allowMultiple = false}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: allowMultiple,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _isUploading = true);
      try {
        List<String> urls = [];
        for (var file in result.files) {
          if (file.bytes != null) {
            final path = 'customer_uploads/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            await Supabase.instance.client.storage.from('agreements').uploadBinary(path, file.bytes!);
            final publicUrl = Supabase.instance.client.storage.from('agreements').getPublicUrl(path);
            urls.add(publicUrl);
          }
        }
        if (urls.isNotEmpty) {
          setState(() {
            _uploadedFiles[label] = urls.join(', ');
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  TextEditingController _getCtrl(String key) {
    _ctrls.putIfAbsent(key, () => TextEditingController());
    return _ctrls[key]!;
  }

  void _submit() {
    Map<String, dynamic> manualDetails = {};

    // 1. Property Details (from new Step 1)
    if (_selectedPropertyId != null) {
      try {
        final prop = widget.properties.firstWhere((p) => p.id == _selectedPropertyId);
        manualDetails['property_name'] = prop.name;
      } catch (_) {}
    }
    // Property address from the form fields (covers both pre-fill and manual)
    if (_ctrls.containsKey('prop_address') && _ctrls['prop_address']!.text.isNotEmpty) {
      manualDetails['property_address'] = _ctrls['prop_address']!.text;
    }
    if (_ctrls.containsKey('prop_city') && _ctrls['prop_city']!.text.isNotEmpty) {
      manualDetails['property_city'] = _ctrls['prop_city']!.text;
    }
    if (_ctrls.containsKey('prop_state') && _ctrls['prop_state']!.text.isNotEmpty) {
      manualDetails['property_state'] = _ctrls['prop_state']!.text;
    }
    if (_ctrls.containsKey('prop_pincode') && _ctrls['prop_pincode']!.text.isNotEmpty) {
      manualDetails['property_pincode'] = _ctrls['prop_pincode']!.text;
    }

    // 2. Owner Details
    if (_ctrls.containsKey('owner_name') && _ctrls['owner_name']!.text.isNotEmpty) {
      manualDetails['owner_name'] = _ctrls['owner_name']!.text;
    }
    if (_ctrls.containsKey('owner_mobile') && _ctrls['owner_mobile']!.text.isNotEmpty) {
      manualDetails['owner_mobile'] = _ctrls['owner_mobile']!.text;
    }

    // 3. Tenant Details
    if (_selectedTenantId != null) {
      try {
        final tenant = widget.tenants.firstWhere((t) => t.id == _selectedTenantId);
        manualDetails['tenant_name'] = tenant.name;
        manualDetails['tenant_mobile'] = tenant.mobile;
      } catch (_) {}
    } else if (_ctrls.containsKey('tenant_name') && _ctrls['tenant_name']!.text.isNotEmpty) {
      manualDetails['tenant_name'] = _ctrls['tenant_name']!.text;
    }

    // 4. Agreement Start and End (from new Step 2)
    if (_ctrls.containsKey('existing_start_date') && _ctrls['existing_start_date']!.text.isNotEmpty) {
      manualDetails['existing_start_date'] = _ctrls['existing_start_date']!.text;
    }
    if (_ctrls.containsKey('existing_end_date') && _ctrls['existing_end_date']!.text.isNotEmpty) {
      manualDetails['existing_end_date'] = _ctrls['existing_end_date']!.text;
    }

    // 5. Rent and Deposit (from new Step 2)
    if (_ctrls.containsKey('existing_rent_amount') && _ctrls['existing_rent_amount']!.text.isNotEmpty) {
      manualDetails['existing_rent_amount'] = _ctrls['existing_rent_amount']!.text;
    }
    if (_ctrls.containsKey('existing_deposit_amount') && _ctrls['existing_deposit_amount']!.text.isNotEmpty) {
      manualDetails['existing_deposit_amount'] = _ctrls['existing_deposit_amount']!.text;
    }

    // Add all remaining filled controllers that weren't already added
    if (_selectedOption == 1 || _selectedOption == 3 || _selectedOption == 2) {
      _ctrls.forEach((key, ctrl) {
        if (!key.startsWith('prop_') && !manualDetails.containsKey(key) && ctrl.text.isNotEmpty) {
          manualDetails[key] = ctrl.text;
        }
      });
      if (_selectedOption == 3) {
        manualDetails['is_existing_agreement'] = true;
      }
    }

    if (_selectedOption == 2) {
      manualDetails['uploaded_files'] = _uploadedFiles;
    }

    if (_selectedCoTenantIds.isNotEmpty) {
      manualDetails['co_tenant_ids'] = _selectedCoTenantIds;
    }

    // Attach uploaded files to all options if any exist
    if (_uploadedFiles.isNotEmpty && _selectedOption != 2) {
      manualDetails['uploaded_files'] = _uploadedFiles;
    }

    widget.onSubmit(
      _selectedService,
      _selectedPropertyId ?? '',
      _selectedTenantId ?? '',
      manualDetails,
    );
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
        _getCtrl(ctrlKey).text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
      _calculateEndDate();
    }
  }

  void _calculateEndDate() {
    final startStr = _getCtrl('existing_start_date').text;
    final durationStr = _getCtrl('existing_duration_months').text;
    
    if (startStr.isNotEmpty && durationStr.isNotEmpty) {
      try {
        final parts = startStr.split('-');
        if (parts.length == 3) {
          final startDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          final months = int.parse(durationStr);
          // Calculate end date: Add months, subtract 1 day
          final endDate = DateTime(startDate.year, startDate.month + months, startDate.day - 1);
          _getCtrl('existing_end_date').text =
              "${endDate.day.toString().padLeft(2, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.year}";
        }
      } catch (e) {
        // ignore
      }
    }
  }

  void _autoFillFromProperty(Property property) {
    _getCtrl('prop_address').text = property.address;
    _getCtrl('prop_city').text = property.city;
    _getCtrl('prop_state').text = property.state;
    _getCtrl('prop_pincode').text = property.pinCode;
    _getCtrl('existing_rent_amount').text = property.rentAmount > 0 ? property.rentAmount.toStringAsFixed(0) : '';
    _getCtrl('existing_deposit_amount').text = property.depositAmount > 0 ? property.depositAmount.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    for (var ctrl in _ctrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _showAddTenantForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTenantForm(properties: widget.properties),
    ).then((_) {
      // Refresh tenants from DatabaseService after adding
      final dbService = context.read<DatabaseService>();
      setState(() {
        _tenants = List<Tenant>.from(dbService.tenants);
        // Auto-select the newest tenant if one was added
        if (_tenants.length > widget.tenants.length && _tenants.isNotEmpty) {
          _selectedTenantId = _tenants.last.id;
        }
      });
    });
  }

  List<Step> get _steps {
    List<Step> steps = [];

    // STEP 0: Select Service & Option
    steps.add(
      Step(
        title: const Text(
          'Service & Method',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        isActive: _currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Type',
              style: TextStyle(color: AppColors.slate600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedService,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0F172A),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: _services
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedService = val!),
            ),
            if (_selectedOption != 3) ...[
              const SizedBox(height: 24),
              const Text(
                'How would you like to proceed?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedOption = 1;
                  _currentStep = 0;
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedOption == 1
                          ? Colors.amber.shade700
                          : AppColors.slate200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedOption == 1
                        ? Colors.amber.shade50
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_document),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Option 1: Fill details yourself',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Manually type in all owner, tenant, and witness details.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedOption = 2;
                  _currentStep = 0;
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedOption == 2
                          ? const Color(0xFF0F172A)
                          : AppColors.slate200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedOption == 2
                        ? AppColors.slate50
                        : Colors.white,
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
                                const Text(
                                  'Option 2: We do it for you',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'RECOMMENDED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Just upload documents. GharBook prepares everything.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              const Text(
                'You have selected to record an existing agreement. Proceed to the next step to enter the details.',
                style: TextStyle(color: AppColors.slate500),
              ),
            ],
          ],
        ),
      ),
    );

    // STEP 1 (Common): Property Address
    steps.add(
      Step(
        title: const Text(
          'Property Address',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        isActive: _currentStep >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Property',
              style: TextStyle(color: AppColors.slate600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _isManualPropertyEntry ? null : _selectedPropertyId,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0F172A),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    '✏️  Enter Manually',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
                ...widget.properties.map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  if (val == null) {
                    _isManualPropertyEntry = true;
                    _selectedPropertyId = null;
                    _getCtrl('prop_address').clear();
                    _getCtrl('prop_city').clear();
                    _getCtrl('prop_state').clear();
                    _getCtrl('prop_pincode').clear();
                    _getCtrl('existing_rent_amount').clear();
                    _getCtrl('existing_deposit_amount').clear();
                  } else {
                    _isManualPropertyEntry = false;
                    _selectedPropertyId = val;
                    final property = widget.properties.firstWhere((p) => p.id == val);
                    _autoFillFromProperty(property);
                    // Also auto-select tenant if property has one
                    if (property.currentTenantId != null && _tenants.any((t) => t.id == property.currentTenantId)) {
                      _selectedTenantId = property.currentTenantId;
                    }
                  }
                });
              },
            ),
            if (_selectedPropertyId != null && !_isManualPropertyEntry) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Address pre-filled from selected property. You can edit below.',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField('prop_address', 'Property Address', maxLines: 2),
            Row(
              children: [
                Expanded(child: _buildTextField('prop_city', 'City')),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('prop_state', 'State')),
              ],
            ),
            _buildTextField('prop_pincode', 'Pin Code'),
          ],
        ),
      ),
    );

    // STEP 2 (Common): Rent & Agreement Period
    steps.add(
      Step(
        title: const Text(
          'Rent & Agreement Period',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        isActive: _currentStep >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedPropertyId != null && !_isManualPropertyEntry)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rent & deposit pre-filled from property. Edit if needed.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'existing_rent_amount',
                    'Rent Amount (₹)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'existing_deposit_amount',
                    'Deposit Amount (₹)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Agreement Period',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate('existing_start_date'),
              child: IgnorePointer(
                child: _buildTextField(
                  'existing_start_date',
                  'Agreement Start Date',
                ),
              ),
            ),
            _buildTextField(
              'existing_duration_months',
              'Period (in Months)',
              onChanged: (_) => _calculateEndDate(),
            ),
            IgnorePointer(
              child: _buildTextField(
                'existing_end_date',
                'Agreement End Date (Auto-calculated)',
              ),
            ),
          ],
        ),
      ),
    );

    if (_selectedOption == 1) {
      // Manual Entry Steps
      steps.add(
        Step(
          title: const Text(
            'Owner & Tenant Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isActive: _currentStep >= steps.length,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Owner Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'Auto-filled (Editable)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField('owner_name', 'Full Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('owner_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildTextField('owner_mobile', 'Mobile'),
                  ),
                ],
              ),
              _buildTextField('owner_email', 'Email'),
              _buildTextField('owner_pan', 'PAN Number'),
              _buildTextField('owner_address', 'Current Address', maxLines: 2),
              for (int i = 1; i <= _coOwnerCount; i++) ...[
                const Divider(height: 16),
                Text(
                  'Co-Owner $i Details',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField('co_owner_${i}_name', 'Full Name'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('co_owner_${i}_age', 'Age'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField('co_owner_${i}_mobile', 'Mobile'),
                    ),
                  ],
                ),
                _buildTextField('co_owner_${i}_pan', 'PAN Number'),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _coOwnerCount++),
                icon: const Icon(Icons.add),
                label: const Text('Add Co-Owner'),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tenant Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'Auto-fill from list:',
                    style: TextStyle(fontSize: 10, color: AppColors.slate500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: null,
                hint: const Text('Add New Tenant'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Add New Tenant',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  ...widget.tenants.map(
                    (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ),
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
                    final tenant = widget.tenants.firstWhere(
                      (t) => t.id == val,
                    );
                    _getCtrl('tenant_name').text = tenant.name;
                    _getCtrl('tenant_mobile').text = tenant.mobile;
                    if (tenant.email != null)
                      _getCtrl('tenant_email').text = tenant.email!;
                    if (tenant.aadhaar != null)
                      _getCtrl('tenant_aadhaar').text = tenant.aadhaar!;
                    if (tenant.pan != null)
                      _getCtrl('tenant_pan').text = tenant.pan!;
                    if (tenant.currentAddress != null)
                      _getCtrl('tenant_address').text = tenant.currentAddress!;
                    if (tenant.permanentAddress != null)
                      _getCtrl('tenant_perm_address').text =
                          tenant.permanentAddress!;
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField('tenant_name', 'Full Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('tenant_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildTextField('tenant_mobile', 'Mobile'),
                  ),
                ],
              ),
              _buildTextField('tenant_email', 'Email'),
              _buildTextField('tenant_pan', 'PAN Number'),
              _buildTextField('tenant_address', 'Current Address', maxLines: 2),
              _buildTextField(
                'tenant_perm_address',
                'Permanent Address',
                maxLines: 2,
              ),
              for (int i = 1; i <= _coTenantCount; i++) ...[
                const Divider(height: 16),
                Text(
                  'Co-Tenant $i Details',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField('co_tenant_${i}_name', 'Full Name'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('co_tenant_${i}_age', 'Age'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField('co_tenant_${i}_mobile', 'Mobile'),
                    ),
                  ],
                ),
                _buildTextField('co_tenant_${i}_pan', 'PAN Number'),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _coTenantCount++),
                icon: const Icon(Icons.add),
                label: const Text('Add Co-Tenant'),
              ),
            ],
          ),
        ),
      );

      steps.add(
        Step(
          title: const Text(
            'Witness Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isActive: _currentStep >= steps.length,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Witness 1',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField('w1_name', 'Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('w1_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildTextField('w1_mobile', 'Mobile'),
                  ),
                ],
              ),
              _buildTextField('w1_address', 'Address', maxLines: 2),
              const Divider(height: 32),
              const Text(
                'Witness 2',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField('w2_name', 'Name'),
              Row(
                children: [
                  Expanded(child: _buildTextField('w2_age', 'Age')),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildTextField('w2_mobile', 'Mobile'),
                  ),
                ],
              ),
              _buildTextField('w2_address', 'Address', maxLines: 2),
            ],
          ),
        ),
      );
    } else if (_selectedOption == 3) {
      // Existing Agreement Steps — property already selected in Step 1
      steps.add(
        Step(
          title: const Text(
            'Select Tenant',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isActive: _currentStep >= steps.length,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tenant (Required)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTenantId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F172A),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _tenants
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedTenantId = val),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showAddTenantForm,
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text(
                  '+ Add New Tenant',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: AppColors.slate300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_selectedTenantId != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Add Co-Tenants (Optional)',
                  style: TextStyle(color: AppColors.slate600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: widget.tenants
                      .where((t) => t.id != _selectedTenantId)
                      .map((t) {
                        final isSelected = _selectedCoTenantIds.contains(t.id);
                        return FilterChip(
                          label: Text(t.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCoTenantIds.add(t.id);
                              } else {
                                _selectedCoTenantIds.remove(t.id);
                              }
                            });
                          },
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _coTenantCount++;
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add New Co-Tenant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFF0F172A)),
                  ),
                ),
                for (int i = 1; i <= _coTenantCount; i++) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Co-Tenant $i',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _coTenantCount--;
                                  _getCtrl('new_co_tenant_${i}_name').clear();
                                  _getCtrl('new_co_tenant_${i}_mobile').clear();
                                  _getCtrl('new_co_tenant_${i}_email').clear();
                                  _getCtrl('new_co_tenant_${i}_aadhaar').clear();
                                  _getCtrl('new_co_tenant_${i}_pan').clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField('new_co_tenant_${i}_name', 'Full Name'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('new_co_tenant_${i}_age', 'Age'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildTextField('new_co_tenant_${i}_mobile', 'Mobile'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField('new_co_tenant_${i}_email', 'Email'),
                        const SizedBox(height: 8),
                        _buildTextField('new_co_tenant_${i}_pan', 'PAN Number'),
                        const SizedBox(height: 8),
                        _buildTextField('new_co_tenant_${i}_aadhaar', 'Aadhaar Number'),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );

      // Agreement Details step removed — rent/deposit/dates are now in common Step 2
    } else {
      // Delegated Step — property already selected in Step 1
      steps.add(
        Step(
          title: const Text(
            'Select Tenant',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isActive: _currentStep >= steps.length,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tenant (Optional)',
                style: TextStyle(color: AppColors.slate600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTenantId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F172A),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _tenants
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedTenantId = val),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showAddTenantForm,
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text(
                  '+ Add New Tenant',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: AppColors.slate300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_selectedTenantId != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Add Co-Tenants (Optional)',
                  style: TextStyle(color: AppColors.slate600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _tenants
                      .where((t) => t.id != _selectedTenantId)
                      .map((t) {
                        final isSelected = _selectedCoTenantIds.contains(t.id);
                        return FilterChip(
                          label: Text(t.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCoTenantIds.add(t.id);
                              } else {
                                _selectedCoTenantIds.remove(t.id);
                              }
                            });
                          },
                        );
                      })
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Agreement Period step removed — now handled by common Step 2

    // Common Steps (Documents and Review)
    if (_selectedOption != 1) {
      steps.add(
      Step(
        title: const Text(
          'Upload Documents',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        isActive: _currentStep >= steps.length,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedOption == 3) ...[
              const Text(
                'Upload your existing rent agreement (Optional).',
                style: TextStyle(color: AppColors.slate600),
              ),
              const SizedBox(height: 24),
              _buildUploadButton('Rent Agreement PDF'),
            ] else ...[
              Text(
                _selectedOption == 1
                    ? 'Enter details and upload documents below.'
                    : 'Upload required documents below.',
                style: const TextStyle(color: AppColors.slate600),
              ),
              const SizedBox(height: 16),
              if (_selectedOption == 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Please fill the address exactly as shown on the Aadhaar card. Original Aadhaar cards for the Owner, Tenant, and both Witnesses must be presented during the biometric appointment.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_selectedOption == 1) const SizedBox(height: 24),

              const Text(
                'Property Proof',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildUploadButton('Property Address Proof (Electric Bill, Index 2, etc.)'),
              const Divider(height: 32),

              const Text(
                'Owner Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_selectedOption == 1) _buildTextField('owner_name', 'Owner Name'),
              _buildUploadButton('Owner Aadhaar', allowMultiple: false),
              _buildUploadButton('Owner PAN', allowMultiple: false),
              for (int i = 1; i <= _coOwnerCount; i++) ...[
                const Divider(height: 16),
                Text(
                  'Co-Owner $i',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_selectedOption == 1) _buildTextField('co_owner_${i}_name', 'Co-Owner $i Name'),
                _buildUploadButton('Co-Owner $i Aadhaar', allowMultiple: false),
                _buildUploadButton('Co-Owner $i PAN', allowMultiple: false),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _coOwnerCount++),
                icon: const Icon(Icons.add),
                label: const Text('Add Co-Owner'),
              ),
              const Divider(height: 32),

              const Text(
                'Tenant Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_selectedOption == 1) _buildTextField('tenant_name', 'Tenant Name'),
              _buildUploadButton('Tenant Aadhaar', allowMultiple: false),
              _buildUploadButton('Tenant PAN', allowMultiple: false),
              for (int i = 1; i <= _coTenantCount; i++) ...[
                const Divider(height: 16),
                Text(
                  'Co-Tenant $i',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_selectedOption == 1) _buildTextField('co_tenant_${i}_name', 'Co-Tenant $i Name'),
                _buildUploadButton(
                  'Co-Tenant $i Aadhaar',
                  allowMultiple: false,
                ),
                _buildUploadButton('Co-Tenant $i PAN', allowMultiple: false),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _coTenantCount++),
                icon: const Icon(Icons.add),
                label: const Text('Add Co-Tenant'),
              ),
              const Divider(height: 32),

              _buildUploadButton('Witness 1 Aadhaar'),
              _buildUploadButton('Witness 2 Aadhaar'),
            ],
          ],
        ),
      ),
    );
    }

    steps.add(
      Step(
        title: const Text(
          'Review & Submit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        isActive: _currentStep >= steps.length,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please verify the details below before submitting.'),
            const SizedBox(height: 16),
            _buildReviewItem('Service', _selectedService),
            _buildReviewItem(
              'Method',
              _selectedOption == 1
                  ? 'Manual Entry'
                  : (_selectedOption == 3
                        ? 'Existing Agreement'
                        : 'GharBook Prepares'),
            ),
            _buildReviewItem(
              'Documents',
              _selectedOption == 3 ? 'Not Required' : 'Uploaded',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedOption == 3
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedOption == 3
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: _selectedOption == 3 ? Colors.green : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedOption == 3
                          ? 'Once submitted, these details will instantly activate the Rent Hub for this property.'
                          : 'Once submitted, our team will verify the documents and process your request within 24 hours.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return steps;
  }

  Widget _buildTextField(
    String key,
    String label, {
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _getCtrl(key),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.slate50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildUploadButton(String label, {bool allowMultiple = false}) {
    final uploaded = _uploadedFiles.containsKey(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _pickFile(label, allowMultiple: allowMultiple),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: uploaded ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uploaded ? Colors.green.shade300 : AppColors.slate300,
            ),
            boxShadow: [
              if (!uploaded)
                BoxShadow(
                  color: AppColors.slate200.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      uploaded ? Icons.check_circle : Icons.upload_file,
                      color: uploaded ? Colors.green.shade600 : AppColors.slate500,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: uploaded ? Colors.green.shade700 : AppColors.slate700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!uploaded)
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepsList = _steps;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Service Request',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stepper(
        key: ValueKey(_selectedOption),
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          // Validate Property Address step (Step 1)
          if (_currentStep == 1) {
            if (_getCtrl('prop_address').text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter the property address.'),
                ),
              );
              return;
            }
          }
          // Validate Rent & Agreement Period step (Step 2)
          if (_currentStep == 2) {
            if (_getCtrl('existing_rent_amount').text.isEmpty ||
                _getCtrl('existing_start_date').text.isEmpty ||
                _getCtrl('existing_duration_months').text.isEmpty ||
                _getCtrl('existing_end_date').text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill rent, start date, and period.'),
                ),
              );
              return;
            }
          }
          // Validate Tenant selection for Option 3 (now at step 3)
          if (_currentStep == 3 && _selectedOption == 3) {
            if (_selectedTenantId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please select a Tenant to activate Rent Hub.',
                  ),
                ),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _currentStep == stepsList.length - 1
                          ? 'Submit Request'
                          : 'Continue',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
