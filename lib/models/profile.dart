/// Mirrors a row of `public.profiles`. Used to show the user's already
/// collected name/email/phone as read-only on screens that would otherwise
/// re-ask for them (see docs/decisions.md #18), and as the editable record
/// on Edit Profile.
class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? memberId;

  /// Storage path (`<user_id>/<file>`) of the profile photo in the private
  /// `avatars` bucket -- NOT a URL. The bucket is private, so a display URL
  /// has to be a short-lived signed one (see `AvatarService.signedUrl`).
  /// Null when the user hasn't uploaded a photo.
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
