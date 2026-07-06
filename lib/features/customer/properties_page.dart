import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../models/tenant.dart';
import '../../models/legal_case.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'create_request_screen.dart';

class PropertiesPage extends StatelessWidget {
  final List<Property> properties;
  final List<Tenant> tenants;
  final List<LegalCase> cases;
  final Function(
    String name,
    String address,
    String city,
    String state,
    String pinCode,
    String type,
    double rent,
    double deposit,
  )?
  onAddProperty;
  final Function(
    String propertyId,
    String name,
    String address,
    String city,
    String state,
    String pinCode,
    String type,
    double rent,
    double deposit,
  )?
  onEditProperty;
  final Function(String propertyId)? onDeleteProperty;
  final VoidCallback? onCreateAgreement;
  final void Function(
    String serviceType,
    String propertyId,
    String tenantId, [
    Map<String, dynamic>?,
  ])?
  onSubmitRequest;

  const PropertiesPage({
    super.key,
    required this.properties,
    required this.tenants,
    this.cases = const [],
    this.onAddProperty,
    this.onEditProperty,
    this.onDeleteProperty,
    this.onCreateAgreement,
    this.onSubmitRequest,
  });

  Future<void> _uploadPhoto(BuildContext context, String propertyId) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading photo...')));
      try {
        final dbService = context.read<DatabaseService>();
        await dbService.uploadPropertyPhoto(
          propertyId,
          result.files.first.name,
          result.files.first.bytes!,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: onAddProperty != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPropertyDialog(context),
              backgroundColor: const Color(0xFF0F172A),
              icon: const Icon(Icons.add_home_work, color: Colors.white),
              label: const Text(
                'Add Property',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: properties.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    size: 60,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No properties found.',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 8),
                  if (onAddProperty != null)
                    ElevatedButton(
                      onPressed: () => _showAddPropertyDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                      ),
                      child: const Text(
                        'Add Your First Property',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final p = properties[index];
                final matchingTenants = tenants.where(
                  (t) => t.id == p.currentTenantId,
                );
                final tenant = matchingTenants.isEmpty
                    ? null
                    : matchingTenants.first;
                final rentHubActive = cases.any((agreementCase) {
                  final details = agreementCase.details;
                  if (details == null ||
                      details['is_existing_agreement'] != true)
                    return false;
                  final casePropertyId =
                      agreementCase.propertyId ??
                      details['property_id']?.toString();
                  return casePropertyId == p.id &&
                      (details['existing_start_date']?.toString().isNotEmpty ??
                          false) &&
                      (details['existing_end_date']?.toString().isNotEmpty ??
                          false) &&
                      (details['existing_rent_pay_date']
                              ?.toString()
                              .isNotEmpty ??
                          false);
                });

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.slate300.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Navigate to property details
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A),
                                    Color(0xFF1E293B),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${p.address}, ${p.city}, ${p.state}',
                                          style: const TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: tenant != null && !rentHubActive
                                            ? () => _showAgreementOptionsDialog(
                                                context,
                                                p.id,
                                                tenant.id,
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: rentHubActive
                                                ? AppColors.emerald500
                                                      .withValues(alpha: 0.2)
                                                : tenant != null
                                                ? Colors.amber.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : AppColors.slate500.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            rentHubActive
                                                ? 'RENT HUB ACTIVE'
                                                : tenant != null
                                                ? 'AGREEMENT PENDING - TAP TO COMPLETE'
                                                : 'VACANT',
                                            style: TextStyle(
                                              color: rentHubActive
                                                  ? Colors.greenAccent
                                                  : tenant != null
                                                  ? Colors.amberAccent
                                                  : Colors.grey,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (onEditProperty != null) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _showEditPropertyDialog(
                                            context,
                                            p,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                      if (onDeleteProperty != null) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _confirmDeleteProperty(
                                            context,
                                            p,
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (tenant == null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showAddTenantDialog(context, p);
                                  },
                                  icon: const Icon(Icons.person_add, size: 14),
                                  label: const Text(
                                    'Add Tenant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: const Color(0xFF0F172A),
                                    minimumSize: const Size(
                                      double.infinity,
                                      36,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (!rentHubActive) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAgreementOptionsDialog(
                                    context,
                                    p.id,
                                    tenant.id,
                                  ),
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Complete Rent Agreement',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: const Color(0xFF0F172A),
                                    minimumSize: const Size(
                                      double.infinity,
                                      36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'MONTHLY RENT',
                                        style: TextStyle(
                                          color: AppColors.slate400,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${p.rentAmount.toInt()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DEPOSIT',
                                        style: TextStyle(
                                          color: AppColors.slate400,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${p.depositAmount.toInt()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (tenant != null) ...[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TENANT',
                                          style: TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tenant.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Mobile: ${tenant.mobile}',
                                          style: const TextStyle(
                                            color: AppColors.slate500,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.photo_library,
                                        size: 14,
                                        color: AppColors.slate400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.photos?.length ?? 0} photos',
                                        style: const TextStyle(
                                          color: AppColors.slate500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _uploadPhoto(context, p.id),
                                    icon: Icon(
                                      Icons.add_a_photo,
                                      size: 14,
                                      color: Colors.indigo.shade600,
                                    ),
                                    label: Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddPropertyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PropertyForm(onSubmit: onAddProperty!),
    );
  }

  void _showEditPropertyDialog(BuildContext context, Property p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PropertyForm(
        existingProperty: p,
        onSubmit: (name, address, city, state, pin, type, rent, deposit) {
          onEditProperty?.call(
            p.id,
            name,
            address,
            city,
            state,
            pin,
            type,
            rent,
            deposit,
          );
        },
      ),
    );
  }

  void _showAddTenantDialog(BuildContext context, Property property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTenantForm(
        property: property,
        existingTenants: tenants,
        onTenantAdded: (tenantId) {
          // After tenant is added, show agreement options
          Navigator.pop(ctx);
          _showAgreementOptionsDialog(context, property.id, tenantId);
        },
      ),
    );
  }

  void _showAgreementOptionsDialog(
    BuildContext context,
    String propertyId,
    String tenantId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Agreement'),
        content: const Text(
          'Choose how you would like to complete the rent agreement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to CreateRequestScreen with Option 3 (Existing Agreement)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateRequestScreen(
                    properties: context.read<DatabaseService>().properties,
                    tenants: context.read<DatabaseService>().tenants,
                    currentUser: context.read<AuthService>().userProfile!,
                    onSubmit:
                        onSubmitRequest ??
                        (serviceType, propId, tenId, [details]) {},
                    initialIsExisting: true,
                    initialPropertyId: propertyId,
                    initialTenantId: tenantId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Record Existing Agreement',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to CreateRequestScreen with Option 1 or 2 (New Agreement)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateRequestScreen(
                    properties: context.read<DatabaseService>().properties,
                    tenants: context.read<DatabaseService>().tenants,
                    currentUser: context.read<AuthService>().userProfile!,
                    onSubmit:
                        onSubmitRequest ??
                        (serviceType, propId, tenId, [details]) {},
                    initialIsExisting: false,
                    initialPropertyId: propertyId,
                    initialTenantId: tenantId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
            ),
            child: const Text(
              'Create New Agreement',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProperty(BuildContext context, Property p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property?'),
        content: Text(
          'Are you sure you want to delete ${p.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && onDeleteProperty != null) {
      onDeleteProperty!(p.id);
    }
  }
}

class _PropertyForm extends StatefulWidget {
  final Property? existingProperty;
  final Function(String, String, String, String, String, String, double, double)
  onSubmit;

  const _PropertyForm({this.existingProperty, required this.onSubmit});

  @override
  State<_PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends State<_PropertyForm> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Maharashtra');
  final _pinCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  String _propertyType = 'Flat';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProperty != null) {
      final p = widget.existingProperty!;
      _nameCtrl.text = p.name;
      _addressCtrl.text = p.address;
      _cityCtrl.text = p.city;
      _stateCtrl.text = p.state;
      _pinCtrl.text = p.pinCode;
      _rentCtrl.text = p.rentAmount.toString();
      _depositCtrl.text = p.depositAmount.toString();
      _propertyType = p.propertyType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingProperty == null
                  ? 'Add New Property'
                  : 'Edit Property',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Property Name (e.g. Flat 402)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Street Address'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: const InputDecoration(labelText: 'Property Type'),
              items: [
                'Flat',
                'Shop',
                'House',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _propertyType = v ?? 'Flat'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _pinCtrl,
                    decoration: const InputDecoration(labelText: 'PIN Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Rent (₹)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _depositCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Deposit (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_nameCtrl.text.isEmpty || _rentCtrl.text.isEmpty)
                        return;
                      setState(() => _isLoading = true);
                      try {
                        await widget.onSubmit(
                          _nameCtrl.text,
                          _addressCtrl.text,
                          _cityCtrl.text,
                          _stateCtrl.text,
                          _pinCtrl.text,
                          _propertyType,
                          double.tryParse(_rentCtrl.text) ?? 0,
                          double.tryParse(_depositCtrl.text) ?? 0,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.slate900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.existingProperty == null
                          ? 'Add Property'
                          : 'Save Changes',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTenantForm extends StatefulWidget {
  final Property property;
  final List<Tenant> existingTenants;
  final Function(String tenantId) onTenantAdded;

  const _AddTenantForm({
    required this.property,
    required this.existingTenants,
    required this.onTenantAdded,
  });

  @override
  State<_AddTenantForm> createState() => _AddTenantFormState();
}

class _AddTenantFormState extends State<_AddTenantForm> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  bool _isLoading = false;
  bool _useExistingTenant = false;
  String? _selectedTenantId;

  @override
  void initState() {
    super.initState();
    if (widget.existingTenants.isNotEmpty) {
      _selectedTenantId = widget.existingTenants.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_useExistingTenant) {
      if (_selectedTenantId == null) return;
      setState(() => _isLoading = true);
      try {
        await context.read<DatabaseService>().assignTenantToProperty(
          _selectedTenantId!,
          widget.property.id,
          widget.property.ownerId,
        );
        if (mounted) widget.onTenantAdded(_selectedTenantId!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error assigning tenant: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    if (_nameCtrl.text.isEmpty || _mobileCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dbService = context.read<DatabaseService>();
      final tenantId = await dbService.addTenant(
        widget.property.id,
        _nameCtrl.text,
        _mobileCtrl.text,
        _emailCtrl.text,
        _addressCtrl.text,
        _panCtrl.text,
        '', // dob not required for basic tenant add
        aadhaar: _aadhaarCtrl.text.isEmpty ? null : _aadhaarCtrl.text,
      );
      await dbService.assignTenantToProperty(
        tenantId,
        widget.property.id,
        widget.property.ownerId,
      );

      if (mounted) {
        widget.onTenantAdded(tenantId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenant added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding tenant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Tenant to Property',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.existingTenants.isNotEmpty) ...[
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.people_outline),
                    label: Text('Existing'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.person_add_outlined),
                    label: Text('New'),
                  ),
                ],
                selected: {_useExistingTenant},
                onSelectionChanged: (value) =>
                    setState(() => _useExistingTenant = value.first),
              ),
            ],
            const SizedBox(height: 16),
            if (_useExistingTenant) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedTenantId,
                decoration: const InputDecoration(labelText: 'Select Tenant'),
                items: widget.existingTenants
                    .map(
                      (tenant) => DropdownMenuItem(
                        value: tenant.id,
                        child: Text('${tenant.name} (${tenant.mobile})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedTenantId = value),
              ),
              const SizedBox(height: 8),
              const Text(
                'If this tenant is linked to another property, they will be moved to this property.',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ] else ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tenant Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Current Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _panCtrl,
                decoration: const InputDecoration(
                  labelText: 'PAN Number (Optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _aadhaarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number (Optional)',
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.slate900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_useExistingTenant ? 'Assign Tenant' : 'Add Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}
