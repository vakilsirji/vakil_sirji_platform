import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/client.dart';
import '../../services/database_service.dart';
import 'client_profile_page.dart';

class ClientsPage extends StatefulWidget {
  final String initialFilter;

  const ClientsPage({super.key, this.initialFilter = 'All Clients'});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All Clients', 'Owners', 'Tenants'];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    int initialIndex = _tabs.indexOf(widget.initialFilter);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    final allClients = dbService.clients;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Clients Directory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
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
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'All Clients'),
                  Tab(text: 'Owners'),
                  Tab(text: 'Tenants'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientList(allClients),
          _buildClientList(allClients.where((c) => c.role == 'owner').toList()),
          _buildClientList(
            allClients.where((c) => c.role == 'tenant').toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClientForm(context, dbService),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'New Client',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildClientList(List<Client> clients) {
    // Apply search filter
    final filtered = clients.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.mobile.toLowerCase().contains(_searchQuery) ||
          (c.email?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            const Text(
              'No clients found.',
              style: TextStyle(color: AppColors.slate500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final client = filtered[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(Client client) {
    final bool isOwner = client.role == 'owner';
    final Color roleColor = isOwner ? Colors.purple : Colors.teal;
    final IconData roleIcon = isOwner ? Icons.home_work : Icons.person;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientProfilePage(client: client),
            ),
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
                  CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.1),
                    radius: 24,
                    child: Icon(roleIcon, color: roleColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isOwner ? 'Owner' : 'Tenant',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {}, // Launch phone call
                        tooltip: 'Call',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.blueAccent),
                        onPressed: () {}, // Launch WhatsApp
                        tooltip: 'Message',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    size: 14,
                    color: AppColors.slate400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    client.mobile,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (client.email != null && client.email!.isNotEmpty) ...[
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      client.email!,
                      style: const TextStyle(
                        color: AppColors.slate600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddClientForm(BuildContext context, DatabaseService dbService) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String mobile = '';
    String email = '';
    String role = 'Owner';
    String address = '';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Client',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => name = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => mobile = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => email = val ?? '',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Owner', 'Tenant']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => role = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => address = val!,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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
                          await dbService.addClient(
                            name,
                            mobile,
                            email,
                            address,
                            role,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Client added successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding client: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'Save Client',
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
        );
      },
    );
  }
}
