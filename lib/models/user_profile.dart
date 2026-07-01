enum UserRole {
  owner, tenant, sales, dataEntry, verification, biometric, manager, admin
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final UserRole role;
  final String? aadhaar;
  final String? pan;
  final String? address;
  final String joinedDate;

  UserProfile({
    required this.id, required this.name, required this.email, required this.mobile,
    required this.role, this.aadhaar, this.pan, this.address, required this.joinedDate,
  });
}
