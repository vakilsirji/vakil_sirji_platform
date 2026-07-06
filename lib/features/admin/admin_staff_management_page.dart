import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStaffManagementPage extends StatefulWidget {
  const AdminStaffManagementPage({super.key});

  @override
  State<AdminStaffManagementPage> createState() =>
      _AdminStaffManagementPageState();
}

class _AdminStaffManagementPageState extends State<AdminStaffManagementPage> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> _staffList = [];
  bool _isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    _fetchStaffList();
  }

  Future<void> _fetchStaffList() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'staff');
      if (mounted) {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(response);
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createStaff() async {
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().adminCreateStaff(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _mobileController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member created successfully!'),
            backgroundColor: AppColors.emerald600,
          ),
        );
        _nameController.clear();
        _mobileController.clear();
        _emailController.clear();
        _passwordController.clear();
        _fetchStaffList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create staff: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Manage Staff',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Staff Member',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a new GharBook employee to the CRM system.',
              style: TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Temporary Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createStaff,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                          : const Text(
                              'Create Staff Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Existing Staff Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingStaff)
              const Center(child: CircularProgressIndicator())
            else if (_staffList.isEmpty)
              const Text(
                'No staff members found.',
                style: TextStyle(color: AppColors.slate500),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _staffList.length,
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF0F172A),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        staff['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${staff['email'] ?? 'No Email'} | ${staff['mobile'] ?? 'No Mobile'}',
                      ),
                      trailing: const Chip(
                        label: Text(
                          'Staff',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
