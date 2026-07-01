class Payment {
  final String id;
  final String entityId;
  final String entityType;
  final double amount;
  final String status;
  final String paymentDate;
  final String? transactionId;
  final String description;

  Payment({
    required this.id, required this.entityId, required this.entityType, required this.amount,
    required this.status, required this.paymentDate, this.transactionId, required this.description,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      entityId: json['entity_id'] ?? '',
      entityType: json['entity_type'] ?? 'Unknown',
      amount: (json['amount'] != null) ? double.parse(json['amount'].toString()) : 0.0,
      status: json['status'] ?? 'Pending',
      paymentDate: json['payment_date'] ?? '',
      transactionId: json['transaction_id'],
      description: json['description'] ?? '',
    );
  }
}
