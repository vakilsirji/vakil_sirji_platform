import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/tenant.dart';
import '../models/legal_case.dart';
import '../models/lead.dart';
import '../models/client.dart';
import '../models/document.dart';
import '../models/payment.dart';
import 'dart:typed_data';

class DatabaseService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache to hold state so the UI doesn't have to rebuild from scratch every time
  List<Property> properties = [];
  List<Tenant> tenants = [];
  List<LegalCase> cases = [];
  List<Lead> leads = [];
  List<Client> clients = [];
  List<Document> documents = [];
  List<Payment> payments = [];

  // Tenant Specific State
  Property? currentTenantProperty;
  Tenant? currentTenantInfo;

  bool isLoading = false;

  void clearData() {
    properties.clear();
    tenants.clear();
    cases.clear();
    leads.clear();
    clients.clear();
    documents.clear();
    payments.clear();
    currentTenantProperty = null;
    currentTenantInfo = null;
    notifyListeners();
  }

  // --- FETCH DATA FOR CUSTOMER DASHBOARD ---
  Future<void> fetchCustomerDashboardData(String userId) async {
    isLoading = true;
    notifyListeners();

    try {
      await _fetchProperties(userId);
      await Future.wait([
        _fetchTenants(),
        _fetchCases(userId),
        _fetchDocuments(),
        _fetchPayments(),
      ]);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- FETCH DATA FOR TENANT DASHBOARD ---
  Future<void> fetchTenantDashboardData(String userMobile) async {
    isLoading = true;
    notifyListeners();

    try {
      // Find tenant record by mobile
      final tenantResponse = await _supabase
          .from('tenants')
          .select()
          .eq('mobile', userMobile)
          .maybeSingle();

      if (tenantResponse != null) {
        currentTenantInfo = Tenant(
          id: tenantResponse['id'],
          name: tenantResponse['name'],
          email: tenantResponse['email'] ?? '',
          mobile: tenantResponse['mobile'],
          aadhaar: tenantResponse['aadhaar'] ?? '',
          pan: tenantResponse['pan'] ?? '',
          currentAddress: tenantResponse['current_address'] ?? '',
          permanentAddress: tenantResponse['permanent_address'] ?? '',
          propertyId: tenantResponse['property_id'],
        );

        // Fetch property
        if (currentTenantInfo!.propertyId != null) {
          final propResponse = await _supabase
              .from('properties')
              .select()
              .eq('id', currentTenantInfo!.propertyId!)
              .maybeSingle();
          if (propResponse != null) {
            currentTenantProperty = Property.fromJson(
              Map<String, dynamic>.from(propResponse),
            );
          }

          // Fetch payments and documents for this property/tenant
          await Future.wait([
            _fetchPaymentsForProperty(currentTenantInfo!.propertyId!),
            _fetchDocumentsForEntity(currentTenantInfo!.propertyId!),
          ]);
        }
      }
    } catch (e) {
      debugPrint('Error fetching tenant dashboard data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPaymentsForProperty(String propertyId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('entity_id', propertyId)
          .order('created_at', ascending: false);
      payments = (response as List)
          .map((json) => Payment.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    }
  }

  Future<void> _fetchDocumentsForEntity(String entityId) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('entity_id', entityId)
          .order('uploaded_at', ascending: false);
      documents = (response as List)
          .map((json) => Document.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    }
  }

  // --- FETCH DATA FOR ADMIN DASHBOARD ---
  Future<void> fetchAdminDashboardData() async {
    isLoading = true;
    notifyListeners();

    try {
      await _fetchAllProperties();
      await Future.wait([
        _fetchTenants(fetchAll: true),
        _fetchAllCases(),
        _fetchAllLeads(),
        _fetchAllClients(),
        _fetchDocuments(),
        _fetchPayments(),
      ]);
    } catch (e) {
      debugPrint('Error fetching admin dashboard data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProperties(String ownerId) async {
    final response = await _supabase
        .from('properties')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    properties = (response as List)
        .map(
          (json) => Property(
            id: json['id'],
            ownerId: json['owner_id'],
            name: json['name'],
            address: json['address'],
            city: json['city'],
            state: json['state'],
            pinCode: json['pin_code'],
            propertyType: json['property_type'] ?? 'Flat',
            photos: json['photos'] != null
                ? List<String>.from(json['photos'])
                : null,
            propertyTaxNumber: json['property_tax_number'],
            electricityBillConsumerNo: json['electricity_bill_consumer_no'],
            rentAmount: (json['rent_amount'] as num).toDouble(),
            depositAmount: (json['deposit_amount'] as num).toDouble(),
            currentTenantId: json['current_tenant_id'],
            propertyTaxDueDate: json['property_tax_due_date'],
            insuranceRenewalDate: json['insurance_renewal_date'],
            reminderEnabled: json['reminder_enabled'] ?? false,
            reminderDueDay: json['reminder_due_day'] ?? 5,
            reminderChannel: json['reminder_channel'] ?? 'WhatsApp',
            lastReminderSentDate: json['last_reminder_sent_date'],
          ),
        )
        .toList();
  }

  Future<void> _fetchAllProperties() async {
    final response = await _supabase
        .from('properties')
        .select()
        .order('created_at', ascending: false);

    properties = (response as List)
        .map(
          (json) => Property(
            id: json['id'],
            ownerId: json['owner_id'],
            name: json['name'],
            address: json['address'],
            city: json['city'],
            state: json['state'],
            pinCode: json['pin_code'],
            propertyType: json['property_type'] ?? 'Flat',
            photos: json['photos'] != null
                ? List<String>.from(json['photos'])
                : null,
            propertyTaxNumber: json['property_tax_number'],
            electricityBillConsumerNo: json['electricity_bill_consumer_no'],
            rentAmount: (json['rent_amount'] as num).toDouble(),
            depositAmount: (json['deposit_amount'] as num).toDouble(),
            currentTenantId: json['current_tenant_id'],
            propertyTaxDueDate: json['property_tax_due_date'],
            insuranceRenewalDate: json['insurance_renewal_date'],
            reminderEnabled: json['reminder_enabled'] ?? false,
            reminderDueDay: json['reminder_due_day'] ?? 5,
            reminderChannel: json['reminder_channel'] ?? 'WhatsApp',
            lastReminderSentDate: json['last_reminder_sent_date'],
          ),
        )
        .toList();
  }

  Future<void> _fetchTenants({bool fetchAll = false}) async {
    final response = await _supabase.from('tenants').select();

    final fetchedTenants = (response as List)
        .map(
          (json) => Tenant(
            id: json['id'],
            name: json['name'] ?? '',
            email: json['email'] ?? '',
            mobile: json['mobile'] ?? '',
            aadhaar: json['aadhaar'] ?? '',
            pan: json['pan'] ?? '',
            currentAddress: json['current_address'] ?? '',
            permanentAddress: json['permanent_address'] ?? '',
            propertyId: json['property_id'],
            emergencyContactName: json['emergency_contact_name'],
            emergencyContactNumber: json['emergency_contact_number'],
            moveInDate: json['move_in_date'],
            moveOutDate: json['move_out_date'],
          ),
        )
        .toList();

    if (!fetchAll) {
      final propertyIds = properties.map((p) => p.id).toSet();
      tenants = fetchedTenants
          .where(
            (t) => t.propertyId != null && propertyIds.contains(t.propertyId),
          )
          .toList();
    } else {
      tenants = fetchedTenants;
    }
  }

  // --- ADD NEW PROPERTY ---
  Future<void> addProperty(
    String ownerId,
    String name,
    String address,
    String city,
    String state,
    String pinCode,
    double rent,
    double deposit, {
    String propertyType = 'Flat',
    List<String>? photos,
  }) async {
    try {
      await _supabase.from('properties').insert({
        'owner_id': ownerId,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'pin_code': pinCode,
        'property_type': propertyType,
        'photos': photos,
        'rent_amount': rent,
        'deposit_amount': deposit,
        'reminder_enabled': false,
        'reminder_due_day': 5,
        'reminder_channel': 'WhatsApp',
      });
      // Refresh properties
      await _fetchProperties(ownerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding property: $e');
      rethrow;
    }
  }

  // --- ADD NEW TENANT ---
  Future<String> addTenant(
    String propertyId,
    String name,
    String mobile,
    String email,
    String address,
    String pan,
    String dob, {
    String? aadhaar,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? moveInDate,
    String? moveOutDate,
  }) async {
    try {
      final response = await _supabase
          .from('tenants')
          .insert({
            'property_id': propertyId,
            'name': name,
            'mobile': mobile,
            'email': email.isEmpty ? null : email,
            'current_address': address,
            'pan': pan,
            'aadhaar': aadhaar,
            'emergency_contact_name': emergencyContactName,
            'emergency_contact_number': emergencyContactNumber,
            'move_in_date': (moveInDate?.isEmpty ?? true) ? null : moveInDate,
            'move_out_date': (moveOutDate?.isEmpty ?? true)
                ? null
                : moveOutDate,
            // Since schema might not have dob, we add it to notes or a custom column if possible,
            // but for now we just satisfy the insert.
          })
          .select()
          .single();

      await _fetchTenants();
      notifyListeners();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error adding tenant: $e');
      rethrow;
    }
  }

  // --- ASSIGN AN EXISTING TENANT TO A PROPERTY ---
  Future<void> assignTenantToProperty(
    String tenantId,
    String propertyId,
    String ownerId,
  ) async {
    try {
      final matchingTenants = tenants.where((item) => item.id == tenantId);
      final tenant = matchingTenants.isEmpty ? null : matchingTenants.first;

      // If this tenant was the active tenant elsewhere, release that property.
      if (tenant?.propertyId != null && tenant!.propertyId != propertyId) {
        await _supabase
            .from('properties')
            .update({'current_tenant_id': null})
            .eq('id', tenant.propertyId!)
            .eq('current_tenant_id', tenantId);
      }

      await _supabase
          .from('tenants')
          .update({'property_id': propertyId})
          .eq('id', tenantId);

      await _supabase
          .from('properties')
          .update({'current_tenant_id': tenantId})
          .eq('id', propertyId);

      await _fetchProperties(ownerId);
      await _fetchTenants();
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning tenant to property: $e');
      rethrow;
    }
  }

  // --- UPDATE PROPERTY ---
  Future<void> updateProperty(
    String propertyId,
    String ownerId,
    String name,
    String address,
    String city,
    String state,
    String pinCode,
    double rent,
    double deposit, {
    String propertyType = 'Flat',
    List<String>? photos,
  }) async {
    try {
      await _supabase
          .from('properties')
          .update({
            'name': name,
            'address': address,
            'city': city,
            'state': state,
            'pin_code': pinCode,
            'property_type': propertyType,
            if (photos != null) 'photos': photos,
            'rent_amount': rent,
            'deposit_amount': deposit,
          })
          .eq('id', propertyId);
      await _fetchProperties(ownerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating property: $e');
      rethrow;
    }
  }

  // --- DELETE PROPERTY ---
  Future<void> deleteProperty(String propertyId, String ownerId) async {
    try {
      await _supabase.from('properties').delete().eq('id', propertyId);
      await _fetchProperties(ownerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting property: $e');
      rethrow;
    }
  }

  // --- UPDATE PROPERTY REMINDER SETTINGS ---
  Future<void> updatePropertyReminderSettings(
    String propertyId,
    String ownerId,
    bool enabled,
    int dueDay,
    String channel,
  ) async {
    try {
      await _supabase
          .from('properties')
          .update({
            'reminder_enabled': enabled,
            'reminder_due_day': dueDay,
            'reminder_channel': channel,
          })
          .eq('id', propertyId);
      await _fetchProperties(ownerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating property reminder settings: $e');
      rethrow;
    }
  }

  // --- UPDATE TENANT ---
  Future<void> updateTenant(
    String tenantId,
    String propertyId,
    String name,
    String mobile,
    String email,
    String address,
    String pan,
    String dob, {
    String? aadhaar,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? moveInDate,
    String? moveOutDate,
  }) async {
    try {
      await _supabase
          .from('tenants')
          .update({
            'property_id': propertyId,
            'name': name,
            'mobile': mobile,
            'email': email.isEmpty ? null : email,
            'current_address': address,
            'pan': pan,
            'aadhaar': aadhaar,
            'emergency_contact_name': emergencyContactName,
            'emergency_contact_number': emergencyContactNumber,
            'move_in_date': (moveInDate?.isEmpty ?? true) ? null : moveInDate,
            'move_out_date': (moveOutDate?.isEmpty ?? true)
                ? null
                : moveOutDate,
          })
          .eq('id', tenantId);
      await _fetchTenants();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating tenant: $e');
      rethrow;
    }
  }

  // --- DELETE TENANT ---
  Future<void> deleteTenant(String tenantId) async {
    try {
      await _supabase.from('tenants').delete().eq('id', tenantId);
      await _fetchTenants();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting tenant: $e');
      rethrow;
    }
  }

  // --- CASES ---
  Future<void> _fetchCases(String customerId) async {
    // We join cases with service_requests
    final response = await _supabase
        .from('cases')
        .select('*, service_requests!inner(*)')
        .eq('service_requests.customer_id', customerId)
        .order('created_at', ascending: false);

    cases = (response as List).map((json) {
      final sr = json['service_requests'];
      return LegalCase(
        id: json['id'],
        requestId: sr['id'],
        title: json['title'],
        customerId: sr['customer_id'],
        propertyId: sr['property_id'] ?? sr['details']?['property_id'],
        tenantId: sr['tenant_id'] ?? sr['details']?['tenant_id'],
        clientName: 'You', // Customer sees their own case
        clientMobile: '',
        serviceType: sr['service_type'],
        status: _parseStatus(json['status']),
        createdAt: (json['created_at'] as String).substring(0, 10),
        updatedAt: (json['updated_at'] as String).substring(0, 10),
        notes: json['notes'],
        documentUrl: json['document_url'],
        details: sr['details'] == null
            ? null
            : Map<String, dynamic>.from(sr['details']),
      );
    }).toList();
  }

  Future<void> _fetchAllCases() async {
    final response = await _supabase
        .from('cases')
        .select('*, service_requests!inner(*)')
        .order('created_at', ascending: false);

    cases = (response as List).map((json) {
      final sr = json['service_requests'];
      return LegalCase(
        id: json['id'],
        requestId: sr['id'],
        title: json['title'],
        customerId: sr['customer_id'],
        propertyId: sr['property_id'],
        tenantId: sr['tenant_id'],
        clientName: 'Tenant/Owner', // Or lookup actual name if we had it
        clientMobile: '',
        serviceType: sr['service_type'],
        status: _parseStatus(json['status']),
        createdAt: (json['created_at'] as String).substring(0, 10),
        updatedAt: (json['updated_at'] as String).substring(0, 10),
        notes: json['notes'],
        documentUrl: json['document_url'],
        details: sr['details'] as Map<String, dynamic>?,
      );
    }).toList();
    notifyListeners();
  }

  // --- LEADS ---
  Future<void> _fetchAllLeads() async {
    final response = await _supabase
        .from('leads')
        .select()
        .order('created_at', ascending: false);
    leads = (response as List)
        .map((json) => Lead.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    notifyListeners();
  }

  // --- CLIENTS ---
  Future<void> _fetchAllClients() async {
    try {
      final List<Client> allClients = [];

      // Fetch Owners
      final ownersResponse = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'owner');
      for (var json in (ownersResponse as List)) {
        allClients.add(
          Client(
            id: json['id'],
            name: json['name'],
            email: json['email'],
            mobile: json['mobile'] ?? '',
            role: 'owner',
            aadhaar: json['aadhaar'],
            pan: json['pan'],
            address: json['address'],
            joinedDate: json['joined_date'] != null
                ? DateTime.tryParse(json['joined_date']) ?? DateTime.now()
                : DateTime.now(),
          ),
        );
      }

      // Fetch Tenants (they might not have an auth profile yet, so we pull from tenants table)
      final tenantsResponse = await _supabase.from('tenants').select();
      for (var json in (tenantsResponse as List)) {
        allClients.add(
          Client(
            id: json['id'],
            name: json['name'],
            email: json['email'],
            mobile: json['mobile'] ?? '',
            role: 'tenant',
            aadhaar: json['aadhaar'],
            pan: json['pan'],
            address: json['current_address'],
            joinedDate: json['created_at'] != null
                ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
                : DateTime.now(),
          ),
        );
      }

      // Sort alphabetically
      allClients.sort((a, b) => a.name.compareTo(b.name));
      clients = allClients;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching clients: $e');
    }
  }

  Future<void> addClient(
    String name,
    String mobile,
    String email,
    String address,
    String role,
  ) async {
    try {
      if (role.toLowerCase() == 'owner') {
        // Since we don't have auth signup here, we just insert into profiles
        // We'll use a dummy UUID or rely on DB default if allowed.
        // Better: We should have a customers table but here we insert into profiles
        // For simplicity, we insert into profiles with a generated UUID
        await _supabase.from('profiles').insert({
          'id':
              '00000000-0000-0000-0000-111111111111', // In a real app, use uuid or auth
          'name': name,
          'mobile': mobile,
          'email': email.isEmpty ? null : email,
          'address': address,
          'role': 'owner',
        });
      } else {
        await _supabase.from('tenants').insert({
          'name': name,
          'mobile': mobile,
          'email': email.isEmpty ? null : email,
          'current_address': address,
        });
      }
      await _fetchAllClients();
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> addLead(
    String name,
    String mobile,
    String source,
    String status,
    String notes,
  ) async {
    try {
      await _supabase.from('leads').insert({
        'name': name,
        'mobile': mobile,
        'source': source,
        'status': status,
        'notes': notes,
      });
      await _fetchAllLeads();
    } catch (e) {
      debugPrint('Error adding lead: $e');
      rethrow;
    }
  }

  Future<void> updateLeadStatus(String leadId, String newStatus) async {
    try {
      await _supabase
          .from('leads')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leadId);

      await _fetchAllLeads();
    } catch (e) {
      debugPrint('Error updating lead status: $e');
      rethrow;
    }
  }

  // --- UPDATE CASE STATUS ---
  Future<void> updateCaseStatus(String caseId, String newStatus) async {
    try {
      await _supabase
          .from('cases')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', caseId);

      // Refresh admin data if it was an admin action (which it is)
      await _fetchAllCases();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating case status: $e');
      rethrow;
    }
  }

  Future<void> deleteCase(String caseId, String customerId) async {
    try {
      await _supabase.from('cases').delete().eq('id', caseId);
      await _fetchCases(customerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting case: $e');
      rethrow;
    }
  }

  Future<void> uploadAgreementDocument(
    String caseId,
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final path = '$caseId/$fileName';

      await _supabase.storage
          .from('agreements')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = _supabase.storage
          .from('agreements')
          .getPublicUrl(path);

      await _supabase
          .from('cases')
          .update({
            'document_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', caseId);

      await _fetchAllCases();
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading agreement: $e');
      rethrow;
    }
  }

  AgreementStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'submitted':
        return AgreementStatus.newRequest;
      case 'documents pending':
        return AgreementStatus.documentsPending;
      case 'data entry':
        return AgreementStatus.dataEntry;
      case 'verification':
        return AgreementStatus.verification;
      case 'draft ready':
        return AgreementStatus.draftReady;
      case 'client approval':
        return AgreementStatus.clientApproval;
      case 'biometric scheduled':
        return AgreementStatus.biometricScheduled;
      case 'biometric completed':
        return AgreementStatus.biometricCompleted;
      case 'government registration':
        return AgreementStatus.governmentRegistration;
      case 'completed':
        return AgreementStatus.completed;
      default:
        return AgreementStatus.newRequest;
    }
  }

  // --- CREATE NEW SERVICE REQUEST ---
  Future<void> createServiceRequest(
    String customerId,
    String serviceType,
    String propertyId,
    String tenantId, {
    Map<String, dynamic>? manualDetails,
  }) async {
    try {
      final detailsJson = <String, dynamic>{
        ...?manualDetails,
        'property_id': propertyId,
        'tenant_id': tenantId,
      };

      // 1. Insert Service Request
      final srResponse = await _supabase
          .from('service_requests')
          .insert({
            'customer_id': customerId,
            'service_type': serviceType,
            'status': 'Submitted',
            'details': detailsJson,
          })
          .select()
          .single();

      // 2. Automatically create the CRM Case for Staff
      await _supabase.from('cases').insert({
        'service_request_id': srResponse['id'],
        'title': '$serviceType Request',
        'status': 'New',
        'notes': 'Automatically generated case from customer request.',
      });

      // 2.5 If existing agreement, automatically update Property for Rent Hub
      if (detailsJson['is_existing_agreement'] == true) {
        if (propertyId.isNotEmpty) {
          final startDate =
              detailsJson['existing_start_date']?.toString().trim() ?? '';
          final endDate =
              detailsJson['existing_end_date']?.toString().trim() ?? '';
          final parsedPayDate = int.tryParse(
            detailsJson['existing_rent_pay_date']?.toString() ?? '',
          );
          final agreementComplete =
              startDate.isNotEmpty &&
              endDate.isNotEmpty &&
              parsedPayDate != null &&
              parsedPayDate >= 1 &&
              parsedPayDate <= 31;
          if (!agreementComplete) {
            await _fetchProperties(customerId);
            await _fetchCases(customerId);
            notifyListeners();
            return;
          }
          final rentAmount =
              double.tryParse(detailsJson['existing_rent_amount'] ?? '0') ??
              0.0;
          final depositAmount =
              double.tryParse(detailsJson['existing_deposit_amount'] ?? '0') ??
              0.0;
          final payDate = parsedPayDate!;
          final updates = <String, dynamic>{
            'rent_amount': rentAmount,
            if (depositAmount > 0) 'deposit_amount': depositAmount,
            'reminder_enabled': true,
            'reminder_due_day': payDate,
            // Temporarily comment out to prevent crashes if user hasn't run the SQL schema update
            // if (endDate != null && endDate.toString().isNotEmpty) 'agreement_end_date': endDate,
          };
          if (tenantId.isNotEmpty) {
            updates['current_tenant_id'] = tenantId;
          }
          await _supabase
              .from('properties')
              .update(updates)
              .eq('id', propertyId);
        }
      }

      // 3. Refresh Data
      await _fetchProperties(customerId);
      await _fetchCases(customerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating service request: $e');
      rethrow;
    }
  }

  // --- STORAGE & DOCUMENTS ---
  Future<String> uploadFileToBucket(
    String bucketName,
    String path,
    Uint8List fileBytes,
  ) async {
    try {
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading file to $bucketName: $e');
      rethrow;
    }
  }

  Future<void> uploadPropertyPhoto(
    String propertyId,
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final path =
          '$propertyId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final fileUrl = await uploadFileToBucket('properties', path, fileBytes);

      final property = properties.firstWhere((p) => p.id == propertyId);
      final List<String> currentPhotos = property.photos != null
          ? List.from(property.photos!)
          : [];
      currentPhotos.add(fileUrl);

      await _supabase
          .from('properties')
          .update({'photos': currentPhotos})
          .eq('id', propertyId);

      await _fetchProperties(property.ownerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading property photo: $e');
      rethrow;
    }
  }

  Future<void> _fetchDocuments() async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .order('uploaded_at', ascending: false);
      documents = (response as List)
          .map((json) => Document.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    }
  }

  Future<void> uploadDocument(
    String entityId,
    String entityType,
    String documentType,
    String fileUrl,
    String uploadedBy,
  ) async {
    try {
      await _supabase.from('documents').insert({
        'entity_id': entityId,
        'entity_type': entityType,
        'document_type': documentType,
        'file_url': fileUrl,
        'uploaded_by': uploadedBy,
      });
      await _fetchDocuments();
    } catch (e) {
      debugPrint('Error uploading document: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String documentId, String fileUrl) async {
    try {
      final urlParts = fileUrl.split('documents/');
      if (urlParts.length > 1) {
        final filePath = urlParts[1];
        await _supabase.storage.from('documents').remove([filePath]);
      }
      await _supabase.from('documents').delete().eq('id', documentId);
      await _fetchDocuments();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  // --- PAYMENTS ---
  Future<void> _fetchPayments() async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .order('created_at', ascending: false);
      payments = (response as List)
          .map((json) => Payment.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    }
  }

  Future<void> addPayment(
    String entityId,
    String entityType,
    double amount,
    String status,
    String paymentDate,
    String? transactionId,
    String description,
  ) async {
    try {
      await _supabase.from('payments').insert({
        'entity_id': entityId,
        'entity_type': entityType,
        'amount': amount,
        'status': status,
        'payment_date': paymentDate,
        'transaction_id': transactionId,
        'description': description,
      });
      await _fetchPayments();
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> generateInvoice(
    String entityId,
    String entityType,
    double amount,
    String description,
  ) async {
    try {
      await _supabase.from('payments').insert({
        'entity_id': entityId,
        'entity_type': entityType,
        'amount': amount,
        'description': description,
        'status': 'Pending',
      });
      await _fetchPayments();
    } catch (e) {
      debugPrint('Error generating invoice: $e');
      rethrow;
    }
  }
}
