class OwnerSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool isTrustedUser;
  final int verificationLevel;

  OwnerSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.isTrustedUser,
    required this.verificationLevel,
  });

  factory OwnerSummary.fromJson(Map<String, dynamic> json) {
    return OwnerSummary(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isTrustedUser: json['isTrustedUser'] as bool? ?? false,
      verificationLevel: json['verificationLevel'] as int? ?? 0,
    );
  }
}

class Listing {
  final String id;
  final String ownerId;
  final OwnerSummary owner;
  final String title;
  final String description;
  final String category;
  final double pricePerDay;
  final double securityDeposit;
  final String rules;
  final double latitude;
  final double longitude;
  final String district;
  final List<String> images;
  final bool isPaused;
  final String status;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.ownerId,
    required this.owner,
    required this.title,
    required this.description,
    required this.category,
    required this.pricePerDay,
    required this.securityDeposit,
    required this.rules,
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.images,
    required this.isPaused,
    required this.status,
    required this.createdAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      owner: OwnerSummary.fromJson(json['owner'] as Map<String, dynamic>),
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      securityDeposit: (json['securityDeposit'] as num).toDouble(),
      rules: json['rules'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      district: json['district'] as String,
      images: (json['images'] as List<dynamic>? ?? []).cast<String>(),
      isPaused: json['isPaused'] as bool? ?? false,
      status: json['status'] as String? ?? 'Approved',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PaginatedListings {
  final List<Listing> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedListings({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedListings.fromJson(Map<String, dynamic> json) {
    return PaginatedListings(
      items: (json['items'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final int verificationLevel;
  final bool isTrustedUser;
  final String? avatarUrl;
  final String role;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.verificationLevel,
    required this.isTrustedUser,
    this.avatarUrl,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      verificationLevel: json['verificationLevel'] as int? ?? 0,
      isTrustedUser: json['isTrustedUser'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'Renter',
    );
  }
}
