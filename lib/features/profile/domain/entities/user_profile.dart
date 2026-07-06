class UserProfile {
  final String name;
  final String role;
  final String avatarUrl;
  final List<String> bioLines;
  final String? state;
  final String? city;
  final bool isJoined;
  final int followersCount;
  final int followingCount;

  const UserProfile({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.bioLines,
    this.state,
    this.city,
    this.isJoined = false,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  UserProfile copyWith({
    String? name,
    String? role,
    String? avatarUrl,
    List<String>? bioLines,
    String? state,
    String? city,
    bool? isJoined,
    int? followersCount,
    int? followingCount,
  }) {
    return UserProfile(
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bioLines: bioLines ?? this.bioLines,
      state: state ?? this.state,
      city: city ?? this.city,
      isJoined: isJoined ?? this.isJoined,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
