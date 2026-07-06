class Property {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String propertyType;
  final List<String>? photos;
  final String? propertyTaxNumber;
  final String? electricityBillConsumerNo;
  final double rentAmount;
  final double depositAmount;
  String? currentTenantId;
  final String? propertyTaxDueDate;
  final String? insuranceRenewalDate;

  bool reminderEnabled;
  int reminderDueDay;
  String reminderChannel;
  String? lastReminderSentDate;
  String? agreementEndDate;

  Property({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    this.propertyType = 'Flat',
    this.photos,
    this.propertyTaxNumber,
    this.electricityBillConsumerNo,
    required this.rentAmount,
    required this.depositAmount,
    this.currentTenantId,
    this.propertyTaxDueDate,
    this.insuranceRenewalDate,
    this.reminderEnabled = false,
    this.reminderDueDay = 5,
    this.reminderChannel = 'WhatsApp',
    this.lastReminderSentDate,
    this.agreementEndDate,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pinCode: json['pin_code'],
      propertyType: json['property_type'] ?? 'Flat',
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
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
      agreementEndDate: json['agreement_end_date'],
    );
  }
}
