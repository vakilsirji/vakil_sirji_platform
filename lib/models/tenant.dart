class Tenant {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String aadhaar;
  final String pan;
  final String currentAddress;
  final String permanentAddress;
  final String? propertyId;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? moveInDate;
  final String? moveOutDate;

  Tenant({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.aadhaar,
    required this.pan,
    required this.currentAddress,
    required this.permanentAddress,
    this.propertyId,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.moveInDate,
    this.moveOutDate,
  });
}
