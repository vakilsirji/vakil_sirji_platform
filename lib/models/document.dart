class Document {
  final String id;
  final String entityId;
  final String entityType;
  final String documentType;
  final String fileUrl;
  final String uploadedBy;
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.documentType,
    required this.fileUrl,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      entityId: json['entity_id'] ?? '',
      entityType: json['entity_type'] ?? 'Unknown',
      documentType: json['document_type'] ?? 'Unknown',
      fileUrl: json['file_url'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
