class UserProfile {
  final String name;
  final String role;
  final String avatarUrl;
  final List<String> bioLines;
  final String? state;
  final String? city;
  final bool isJoined;

  const UserProfile({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.bioLines,
    this.state,
    this.city,
    this.isJoined = false,
  });

  UserProfile copyWith({
    String? name,
    String? role,
    String? avatarUrl,
    List<String>? bioLines,
    String? state,
    String? city,
    bool? isJoined,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bioLines: bioLines ?? this.bioLines,
      state: state ?? this.state,
      city: city ?? this.city,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
