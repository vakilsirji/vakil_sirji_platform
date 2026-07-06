import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../models/user_profile.dart';
import '../../models/payment.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'overview_page.dart';
import 'cases_page.dart';
import 'properties_page.dart';
import 'payments_tracker_page.dart';
import 'create_request_screen.dart';
import 'profile_page.dart';
import 'tenants_page.dart';
import 'agreements_page.dart';
import 'document_vault_page.dart';
import '../../services/database_service.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;
  late UserProfile _currentUser;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Fetch live data from Supabase! We will start fetching after context is available in didChangeDependencies or directly grab from Provider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the real current user from AuthService
    final authService = context.watch<AuthService>();
    final dbService = context.read<DatabaseService>();
    if (authService.userProfile != null && !_initialized) {
      _currentUser = authService.userProfile!;
      _initialized = true;
      // Fetch live data if not already loading
      if (!dbService.isLoading) {
        Future.microtask(() {
          dbService.clearData();
          dbService.fetchCustomerDashboardData(_currentUser.id);
        });
      }
    }
  }

  void _addNewCase(
    String serviceType,
    String propertyId,
    String tenantId, [
    Map<String, dynamic>? manualDetails,
  ]) async {
    final dbService = context.read<DatabaseService>();
    try {
      await dbService.createServiceRequest(
        _currentUser.id,
        serviceType,
        propertyId,
        tenantId,
        manualDetails: manualDetails,
      );
      if (mounted) {
        final isOption3 =
            manualDetails != null &&
            manualDetails['is_existing_agreement'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOption3
                  ? 'Agreement recorded and Rent Hub activated successfully!'
                  : 'Service Request Submitted successfully! Case Created in CRM.',
            ),
            backgroundColor: AppColors.emerald600,
          ),
        );
        setState(() {}); // Refresh UI with new cases
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = context.watch<DatabaseService>();
    if (dbService.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Syncing with GharBook Servers...'),
            ],
          ),
        ),
      );
    }

    final properties = dbService.properties;
    final tenants = dbService.tenants;
    final cases = dbService.cases;
    // We don't have payments in the DB service yet, just use an empty list for now
    final payments = <Payment>[];

    final List<Widget> pages = [
      OverviewPage(
        user: _currentUser,
        properties: properties,
        tenants: tenants,
        payments: payments,
        cases: cases,
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      AgreementsPage(
        cases: cases,
        onRequestRenewal: () {
          // Trigger renewal logic
        },
        onDeleteAgreement: (id) async {
          final dbs = context.read<DatabaseService>();
          await dbs.deleteCase(id, _currentUser.id);
          if (mounted) setState(() {});
        },
        onUploadDocument: (caseId, fileName, bytes) async {
          final dbs = context.read<DatabaseService>();
          await dbs.uploadAgreementDocument(caseId, fileName, bytes);
          if (mounted) setState(() {});
        },
      ),
      PropertiesPage(
        properties: properties,
        tenants: tenants,
        cases: cases,
        onAddProperty:
            (name, address, city, state, pin, type, rent, deposit) async {
              final dbs = context.read<DatabaseService>();
              await dbs.addProperty(
                _currentUser.id,
                name,
                address,
                city,
                state,
                pin,
                rent,
                deposit,
                propertyType: type,
              );
              if (mounted) setState(() {});
            },
        onCreateAgreement: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRequestScreen(
                properties: properties,
                tenants: tenants,
                currentUser: _currentUser,
                onSubmit: _addNewCase,
              ),
            ),
          );
        },
        onSubmitRequest: _addNewCase,
        onEditProperty:
            (id, name, address, city, state, pin, type, rent, deposit) async {
              final dbs = context.read<DatabaseService>();
              await dbs.updateProperty(
                id,
                _currentUser.id,
                name,
                address,
                city,
                state,
                pin,
                rent,
                deposit,
                propertyType: type,
              );
              if (mounted) setState(() {});
            },
        onDeleteProperty: (id) async {
          final dbs = context.read<DatabaseService>();
          await dbs.deleteProperty(id, _currentUser.id);
          if (mounted) setState(() {});
        },
      ),
      TenantsPage(
        tenants: tenants,
        onAddTenant: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => AddTenantForm(properties: properties),
          );
        },
        onEditTenant: (tenant) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) =>
                AddTenantForm(properties: properties, existingTenant: tenant),
          );
        },
        onDeleteTenant: (id) async {
          final dbs = context.read<DatabaseService>();
          await dbs.deleteTenant(id);
          if (mounted) setState(() {});
        },
      ),
      PaymentsTrackerPage(
        properties: properties,
        tenants: tenants,
        payments: dbService.payments,
        onSaveReminderSettings: (propId, enabled, dueDay, channel) async {
          await dbService.updatePropertyReminderSettings(
            propId,
            _currentUser.id,
            enabled,
            dueDay,
            channel,
          );
          if (mounted) setState(() {});
        },
        onAddPayment: (payment) async {
          await dbService.addPayment(
            payment.entityId,
            payment.entityType,
            payment.amount,
            payment.status,
            payment.paymentDate,
            payment.transactionId,
            payment.description,
          );
          if (mounted) setState(() {});
        },
      ),
      DocumentVaultPage(
        documents: dbService.documents,
        currentUserId: _currentUser.id,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the application or sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                  await context.read<AuthService>().signOut();
                },
                child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.slate50,
      appBar: AppBar(
        leading: _currentIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'GharBook',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active,
              color: Colors.amber,
              size: 20,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfilePage(user: _currentUser, isStandalone: true),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SafeArea(child: pages[_currentIndex]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.slate300.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0F172A),
            unselectedItemColor: AppColors.slate400,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Agreements',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business),
                label: 'Properties',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'Tenants',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'Rent Hub',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'Vault',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'fab_record',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRequestScreen(
                          properties: properties,
                          tenants: tenants,
                          currentUser: _currentUser,
                          onSubmit: _addNewCase,
                          initialIsExisting: true,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue.shade700,
                  icon: const Icon(Icons.history_edu, color: Colors.white),
                  label: const Text(
                    'Record Existing Agreement',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: 'fab_create',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRequestScreen(
                          properties: properties,
                          tenants: tenants,
                          currentUser: _currentUser,
                          onSubmit: _addNewCase,
                          initialIsExisting: false,
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF0F172A),
                  icon: const Icon(Icons.add, color: Colors.amber),
                  label: const Text(
                    'Create Agreement',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : null,
      ),
    );
  }
}
