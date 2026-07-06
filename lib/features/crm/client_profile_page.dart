import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/client.dart';
import '../../models/property.dart';
import '../../models/legal_case.dart';
import '../../models/document.dart';
import '../../services/database_service.dart';

class ClientProfilePage extends StatelessWidget {
  final Client client;

  const ClientProfilePage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final isOwner = client.role == 'owner';

    // Filter global state for this specific client
    List<Property> clientProperties = [];
    if (isOwner) {
      clientProperties = dbService.properties
          .where((p) => p.ownerId == client.id)
          .toList();
    } else {
      // If tenant, find the property they are renting
      final tenantRecord = dbService.tenants
          .where((t) => t.id == client.id)
          .firstOrNull;
      if (tenantRecord != null) {
        final prop = dbService.properties
            .where((p) => p.id == tenantRecord.propertyId)
            .firstOrNull;
        if (prop != null) {
          clientProperties = [prop];
        }
      }
    }

    final clientCases = dbService.cases.where((c) {
      if (isOwner) return c.customerId == client.id;
      return c.tenantId == client.id; // tenant cases
    }).toList();

    final clientDocs = dbService.documents
        .where((d) => d.entityId == client.id)
        .toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F172A),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderContent(),
                ),
                bottom: const TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.blueAccent,
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'Properties'),
                    Tab(text: 'Cases & Services'),
                    Tab(text: 'Documents'),
                    Tab(text: 'Timeline'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildPropertiesTab(clientProperties, isOwner),
              _buildCasesTab(clientCases),
              _buildDocumentsTab(clientDocs),
              _buildTimelineTab(clientCases),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    final bool isOwner = client.role == 'owner';
    final Color roleColor = isOwner ? Colors.purpleAccent : Colors.tealAccent;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: Text(
              client.name.isNotEmpty
                  ? client.name.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            client.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              isOwner ? 'Property Owner' : 'Tenant',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                client.mobile,
                style: const TextStyle(color: Colors.white70),
              ),
              if (client.email != null && client.email!.isNotEmpty) ...[
                const SizedBox(width: 24),
                const Icon(Icons.email, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  client.email!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab(List<Property> properties, bool isOwner) {
    if (properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              isOwner
                  ? 'No properties added yet.'
                  : 'No active rented property.',
              style: const TextStyle(color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final p = properties[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_city, color: Colors.blue),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${p.address}, ${p.city}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 14,
                      color: Colors.green,
                    ),
                    Text(
                      '${p.rentAmount}/mo',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCasesTab(List<LegalCase> cases) {
    if (cases.isEmpty) {
      return const Center(
        child: Text(
          'No cases or services found.',
          style: TextStyle(color: AppColors.slate500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.slate100,
              child: const Icon(Icons.assignment, color: Color(0xFF0F172A)),
            ),
            title: Text(
              c.serviceType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Status: ${c.status}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab(List<Document> documents) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            const Text(
              'Document Vault',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'No documents uploaded for this client yet.',
              style: TextStyle(color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        IconData docIcon = Icons.insert_drive_file;
        if (doc.documentType.toLowerCase().contains('aadhaar') ||
            doc.documentType.toLowerCase().contains('pan')) {
          docIcon = Icons.badge;
        } else if (doc.documentType.toLowerCase().contains('bill')) {
          docIcon = Icons.receipt;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: Icon(docIcon, color: Colors.blueAccent),
            ),
            title: Text(
              doc.documentType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Uploaded: ${doc.uploadedAt.toLocal().toString().substring(0, 10)}',
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            trailing: const Icon(Icons.download, color: AppColors.slate400),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab(List<LegalCase> cases) {
    final sortedCases = List<LegalCase>.from(cases)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildTimelineItem(
          title: 'Client Joined',
          description: 'Added to GharBook platform.',
          date: client.joinedDate,
          icon: Icons.person_add,
          color: Colors.blue,
        ),
        for (var c in sortedCases)
          _buildTimelineItem(
            title: 'Service Requested',
            description: '${c.serviceType} request initiated.',
            date: DateTime.parse(c.createdAt),
            icon: Icons.add_task,
            color: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String description,
    required DateTime date,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 8),
              Container(width: 2, height: 40, color: AppColors.slate200),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.slate600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
