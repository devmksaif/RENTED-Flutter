class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl; // API returns as avatar_url
  final String verificationStatus;
  final DateTime? verifiedAt;
  final DateTime? emailVerifiedAt; // email_verified_at from database
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.verificationStatus,
    this.verifiedAt,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle simplified user objects (e.g., product owner with only id/name)
    final now = DateTime.now();

    return User(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? 'no-email@placeholder.com',
      avatarUrl: json['avatar_url'],
      verificationStatus: json['verification_status'] ?? 'pending',
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : now,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'verification_status': verificationStatus,
      'verified_at': verifiedAt?.toIso8601String(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
}
