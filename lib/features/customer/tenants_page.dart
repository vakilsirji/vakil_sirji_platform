import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/tenant.dart';

class TenantsPage extends StatelessWidget {
  final List<Tenant> tenants;
  final VoidCallback? onAddTenant;
  final Function(Tenant)? onEditTenant;
  final Function(String)? onDeleteTenant;

  const TenantsPage({
    super.key,
    required this.tenants,
    this.onAddTenant,
    this.onEditTenant,
    this.onDeleteTenant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: onAddTenant != null
          ? FloatingActionButton.extended(
              onPressed: onAddTenant,
              backgroundColor: const Color(0xFF0F172A),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Add Tenant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: tenants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_outlined,
                    size: 60,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tenants found.',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 8),
                  if (onAddTenant != null)
                    ElevatedButton(
                      onPressed: onAddTenant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                      ),
                      child: const Text(
                        'Add Your First Tenant',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final t = tenants[index];
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
                          // TODO: Navigate to tenant details
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
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.white24,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.email,
                                          style: const TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: AppColors.slate400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t.mobile,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppColors.slate400,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          t.currentAddress.isNotEmpty
                                              ? t.currentAddress
                                              : 'No address provided',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.slate600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PAN',
                                            style: TextStyle(
                                              color: AppColors.slate400,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t.pan.isNotEmpty ? t.pan : 'N/A',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'AADHAAR',
                                            style: TextStyle(
                                              color: AppColors.slate400,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t.aadhaar.isNotEmpty
                                                ? t.aadhaar
                                                : 'N/A',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (onEditTenant != null)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.black54,
                                            size: 20,
                                          ),
                                          onPressed: () => onEditTenant!(t),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      if (onDeleteTenant != null)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteTenant(context, t),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
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

  Future<void> _confirmDeleteTenant(BuildContext context, Tenant t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tenant?'),
        content: Text(
          'Are you sure you want to delete ${t.name}? This action cannot be undone.',
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

    if (confirmed == true && onDeleteTenant != null) {
      onDeleteTenant!(t.id);
    }
  }
}
