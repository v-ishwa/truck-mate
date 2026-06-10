class UserProfile {
  final String name;
  final String role;
  final String avatarUrl;
  final List<String> bioLines;
  final bool isJoined;

  const UserProfile({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.bioLines,
    this.isJoined = false,
  });

  UserProfile copyWith({
    String? name,
    String? role,
    String? avatarUrl,
    List<String>? bioLines,
    bool? isJoined,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bioLines: bioLines ?? this.bioLines,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
