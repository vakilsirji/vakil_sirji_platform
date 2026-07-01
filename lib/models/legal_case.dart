enum AgreementStatus {
  newRequest, documentsPending, dataEntry, verification, draftReady,
  clientApproval, biometricScheduled, biometricCompleted, governmentRegistration, completed
}

class LegalCase {
  final String id;
  final String requestId;
  final String title;
  final String customerId;
  final String clientName;
  final String clientMobile;
  final String serviceType;
  final AgreementStatus status;
  final String createdAt;
  final String updatedAt;
  final String? propertyId;
  final String? tenantId;
  final String? notes;
  final String? documentUrl;
  final Map<String, dynamic>? details;

  LegalCase({
    required this.id, required this.requestId, required this.title, required this.customerId,
    this.propertyId, this.tenantId, this.documentUrl, this.details,
    required this.clientName, required this.clientMobile, required this.serviceType,
    required this.status, required this.createdAt, required this.updatedAt, this.notes,
  });
}
