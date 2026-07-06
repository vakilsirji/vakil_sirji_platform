class Lead {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String source;
  final String status;
  final String? notes;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lead({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.source,
    required this.status,
    this.notes,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      source: json['source'] ?? 'Website',
      status: json['status'] ?? 'New Lead',
      notes: json['notes'],
      assignedTo: json['assigned_to'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'source': source,
      'status': status,
      'notes': notes,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
