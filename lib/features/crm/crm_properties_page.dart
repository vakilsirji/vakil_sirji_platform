import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/database_service.dart';

class CrmPropertiesPage extends StatefulWidget {
  const CrmPropertiesPage({super.key});

  @override
  State<CrmPropertiesPage> createState() => _CrmPropertiesPageState();
}

class _CrmPropertiesPageState extends State<CrmPropertiesPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final properties = dbService.properties;

    final filtered = properties.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery) ||
          p.address.toLowerCase().contains(_searchQuery) ||
          p.city.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Properties Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by property name, address, or city...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPropertyForm(context, dbService),
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add_home, color: Colors.white),
        label: const Text(
          'New Property',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No properties found.',
                    style: TextStyle(color: AppColors.slate500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final property = filtered[index];

                // Find Owner Name
                final owner = dbService.clients
                    .where((c) => c.id == property.ownerId)
                    .firstOrNull;
                // Find Active Tenant (if any)
                final tenant = dbService.tenants
                    .where((t) => t.propertyId == property.id)
                    .firstOrNull;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      _showPropertyDetails(
                        context,
                        property,
                        owner?.name,
                        tenant?.name,
                        dbService,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_city,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${property.address}, ${property.city}',
                                      style: const TextStyle(
                                        color: AppColors.slate500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Owner',
                                    style: TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    owner?.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tenant',
                                    style: TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    tenant?.name ?? 'Vacant',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: tenant != null
                                          ? Colors.teal
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Rent',
                                    style: TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹${property.rentAmount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
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

  void _showPropertyDetails(
    BuildContext context,
    Property property,
    String? ownerName,
    String? tenantName,
    DatabaseService dbService,
  ) {
    // Basic bottom sheet for property details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(bottomSheetContext).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Property Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Property Name', property.name),
              _buildDetailRow(
                'Address',
                '${property.address}, ${property.city}, ${property.state} - ${property.pinCode}',
              ),
              const Divider(),
              _buildDetailRow('Owner', ownerName ?? 'Unknown'),
              _buildDetailRow('Current Tenant', tenantName ?? 'Vacant'),
              const Divider(),
              _buildDetailRow('Monthly Rent', '₹${property.rentAmount}'),
              _buildDetailRow('Deposit Amount', '₹${property.depositAmount}'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open Documents
                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Property Documents Vault coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder, color: Colors.white),
                  label: const Text(
                    'View Documents',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Start new case
                    Navigator.pop(bottomSheetContext);
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text(
                    'Start New Agreement',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _showAddPropertyForm(BuildContext context, DatabaseService dbService) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String address = '';
    String city = 'Pune';
    String state = 'Maharashtra';
    String pinCode = '';
    double rent = 0.0;
    double deposit = 0.0;
    // We'll use a dummy owner ID for now since we're not building a complex picker
    String dummyOwnerId = '00000000-0000-0000-0000-111111111111';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Property',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Property Name/Tag',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => name = val!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Full Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => address = val!,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: city,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => city = val!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'PIN Code',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (val) => pinCode = val!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Monthly Rent (₹)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                          onSaved: (val) => rent = double.tryParse(val!) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Deposit (₹)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (val) =>
                              deposit = double.tryParse(val!) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          Navigator.pop(bottomSheetContext);

                          try {
                            await dbService.addProperty(
                              dummyOwnerId,
                              name,
                              address,
                              city,
                              state,
                              pinCode,
                              rent,
                              deposit,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Property added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding property: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text(
                        'Save Property',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
