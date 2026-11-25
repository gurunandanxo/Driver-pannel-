class DriverProfile {
  final String id;
  final String? authUserId;
  final String driverId; // e.g. 'TUM-DRV-1042'
  final String name;
  final String kannadaName;
  final String phone;
  final String email;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String licenseNumber;
  final String? licenseExpiry;
  final String? experience;
  final String? driverCategory;
  final String badgeNumber;
  final String depotId;
  final String depotName;
  final String? profilePhotoUrl;
  final String role; // 'Senior Driver', 'Transit Driver', 'Driver'
  final String accountStatus; // 'ACTIVE', 'PENDING', 'SUSPENDED', 'INACTIVE'

  const DriverProfile({
    required this.id,
    this.authUserId,
    required this.driverId,
    required this.name,
    this.kannadaName = '',
    required this.phone,
    required this.email,
    this.dateOfBirth,
    this.address,
    this.city = 'Tumakuru',
    this.emergencyContactName,
    this.emergencyContactNumber,
    required this.licenseNumber,
    this.licenseExpiry,
    this.experience = '3-5 Years',
    this.driverCategory = 'Heavy Passenger Vehicle (HPV)',
    this.badgeNumber = '',
    this.depotId = 'DEPOT_01',
    this.depotName = 'Tumakuru Central City Depot #1 (Ashoka Road)',
    this.profilePhotoUrl,
    this.role = 'Driver',
    this.accountStatus = 'ACTIVE',
  });

  String get initials {
    if (name.isEmpty) return 'D';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  bool get isApproved => accountStatus.toUpperCase() == 'ACTIVE';
  bool get isPending => accountStatus.toUpperCase() == 'PENDING';
  bool get isSuspended => accountStatus.toUpperCase() == 'SUSPENDED';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id']?.toString() ?? '',
      authUserId: json['auth_user_id']?.toString() ?? json['user_id']?.toString(),
      driverId: json['driver_id']?.toString() ?? json['driverId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? 'Driver',
      kannadaName: json['kannada_name']?.toString() ?? json['kannadaName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString() ?? 'Tumakuru',
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactNumber: json['emergency_contact_number']?.toString(),
      licenseNumber: json['license_number']?.toString() ?? json['licence_number']?.toString() ?? json['licenseNumber']?.toString() ?? '',
      licenseExpiry: json['license_expiry']?.toString() ?? json['licence_expiry']?.toString(),
      experience: json['experience']?.toString() ?? '3-5 Years',
      driverCategory: json['driver_category']?.toString() ?? 'Heavy Passenger Vehicle (HPV)',
      badgeNumber: json['badge_number']?.toString() ?? json['badgeNumber']?.toString() ?? '',
      depotId: json['depot_id']?.toString() ?? json['depotId']?.toString() ?? 'DEPOT_01',
      depotName: json['depot_name']?.toString() ?? json['depotName']?.toString() ?? json['depot']?.toString() ?? 'Tumakuru Central City Depot #1 (Ashoka Road)',
      profilePhotoUrl: json['profile_photo_url']?.toString() ?? json['profile_image_url']?.toString() ?? json['profilePhotoUrl']?.toString(),
      role: json['role']?.toString() ?? 'Driver',
      accountStatus: json['account_status']?.toString() ?? json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'auth_user_id': authUserId,
        'user_id': authUserId,
        'driver_id': driverId,
        'name': name,
        'full_name': name,
        'kannada_name': kannadaName,
        'phone': phone,
        'mobile': phone,
        'email': email,
        'date_of_birth': dateOfBirth,
        'address': address,
        'city': city,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_number': emergencyContactNumber,
        'license_number': licenseNumber,
        'licence_number': licenseNumber,
        'license_expiry': licenseExpiry,
        'licence_expiry': licenseExpiry,
        'experience': experience,
        'driver_category': driverCategory,
        'badge_number': badgeNumber,
        'depot_id': depotId,
        'depot_name': depotName,
        'depot': depotName,
        'profile_photo_url': profilePhotoUrl,
        'profile_image_url': profilePhotoUrl,
        'role': role,
        'account_status': accountStatus,
        'status': accountStatus,
      };

  DriverProfile copyWith({
    String? id,
    String? authUserId,
    String? driverId,
    String? name,
    String? kannadaName,
    String? phone,
    String? email,
    String? dateOfBirth,
    String? address,
    String? city,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? licenseNumber,
    String? licenseExpiry,
    String? experience,
    String? driverCategory,
    String? badgeNumber,
    String? depotId,
    String? depotName,
    String? profilePhotoUrl,
    String? role,
    String? accountStatus,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      kannadaName: kannadaName ?? this.kannadaName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      experience: experience ?? this.experience,
      driverCategory: driverCategory ?? this.driverCategory,
      badgeNumber: badgeNumber ?? this.badgeNumber,
      depotId: depotId ?? this.depotId,
      depotName: depotName ?? this.depotName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}
