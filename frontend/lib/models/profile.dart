class Profile {
  final String id;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String? address;
  final String? city;
  final String membershipTier;
  final DateTime? membershipExpiresAt;
  final bool emailVerified;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.address,
    this.city,
    required this.membershipTier,
    this.membershipExpiresAt,
    required this.emailVerified,
    this.avatarUrl,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      membershipTier: json['membership_tier'] as String? ?? 'free',
      membershipExpiresAt: json['membership_expires_at'] != null
          ? DateTime.parse(json['membership_expires_at'] as String)
          : null,
      emailVerified: json['email_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'city': city,
      'membership_tier': membershipTier,
      'membership_expires_at': membershipExpiresAt?.toIso8601String(),
      'email_verified': emailVerified,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
