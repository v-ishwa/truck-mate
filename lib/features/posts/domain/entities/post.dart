class Post {
  final String id;
  final String userName;
  final String role;
  final String avatarUrl;
  final String timeAgo;
  final String statusText;
  final String imageUrl;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isBookmarked;
  final String caption;
  final List<String> tags;
  final bool hasRouteCard;
  final String? fromLocation;
  final String? toLocation;
  final String? departureTime;
  final String? contactNumber;

  const Post({
    required this.id,
    required this.userName,
    required this.role,
    required this.avatarUrl,
    required this.timeAgo,
    required this.statusText,
    required this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isBookmarked,
    required this.caption,
    required this.tags,
    this.hasRouteCard = false,
    this.fromLocation,
    this.toLocation,
    this.departureTime,
    this.contactNumber,
  });

  Post copyWith({
    String? id,
    String? userName,
    String? role,
    String? avatarUrl,
    String? timeAgo,
    String? statusText,
    String? imageUrl,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isBookmarked,
    String? caption,
    List<String>? tags,
    bool? hasRouteCard,
    String? fromLocation,
    String? toLocation,
    String? departureTime,
    String? contactNumber,
  }) {
    return Post(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timeAgo: timeAgo ?? this.timeAgo,
      statusText: statusText ?? this.statusText,
      imageUrl: imageUrl ?? this.imageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      hasRouteCard: hasRouteCard ?? this.hasRouteCard,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      departureTime: departureTime ?? this.departureTime,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }
}
