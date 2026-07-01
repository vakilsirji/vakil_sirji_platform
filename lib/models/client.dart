class Client {
  final String id;
  final String name;
  final String? email;
  final String mobile;
  final String role; // 'owner' or 'tenant'
  final String? aadhaar;
  final String? pan;
  final String? address;
  final DateTime joinedDate;

  Client({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    required this.role,
    this.aadhaar,
    this.pan,
    this.address,
    required this.joinedDate,
  });
}
