class ProfileModel {
  final int id;
  final String firebaseUid;
  final String email;
  final String name;
  final String role;
  final bool emailVerified;

  ProfileModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.role,
    required this.emailVerified,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Parsing ID yang tahan banting (mencegah error String vs int)
    int parsedId = 0;
    if (json['ID'] != null) {
      parsedId = int.tryParse(json['ID'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    return ProfileModel(
      id: parsedId,
      firebaseUid: json['firebase_uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      // Pastikan konversi boolean aman
      emailVerified: json['email_verified'] == true || json['email_verified'] == 'true',
    );
  }
}