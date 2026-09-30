/// A row of `profiles`.
class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? memberId;

  /// Path of the profile photo in the private `avatars` bucket (not a URL; see
  /// AvatarService.signedUrl). Null if there's no photo.
  final String? avatarUrl;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.memberId,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String?,
      memberId: json['member_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
