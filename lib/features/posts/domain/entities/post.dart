import '../../../../core/network/api_constants.dart';

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

  /// Create a Post from backend JSON response
  factory Post.fromJson(Map<String, dynamic> json) {
    final from = json['fromLocation'] as String?;
    final to = json['toLocation'] as String?;
    final hasRoute = from != null && from.isNotEmpty && to != null && to.isNotEmpty;

    // Build the status text from available fields
    final parts = <String>[];
    if (hasRoute) {
      parts.add('$from → $to 📍');
    }
    if (json['travelDate'] != null && (json['travelDate'] as String).isNotEmpty) {
      final timeStr = json['travelTime'] ?? '';
      parts.add('${json['travelDate']}${timeStr.isNotEmpty ? ', $timeStr' : ''} ⏰');
    }
    if (json['description'] != null && (json['description'] as String).isNotEmpty) {
      parts.add(json['description']);
    }
    final statusText = parts.isNotEmpty ? parts.join('\n') : 'New post';

    // Build caption
    final caption = json['description'] ?? '';

    // Build tags from locations
    final tags = <String>[];
    if (from != null && from.isNotEmpty) tags.add('#${from.split(',').first.trim().replaceAll(' ', '')}');
    if (to != null && to.isNotEmpty) tags.add('#${to.split(',').first.trim().replaceAll(' ', '')}');
    tags.add('#TruckMate');

    // Calculate time ago from createdAt
    final timeAgo = _calculateTimeAgo(json['createdAt'] as String?);

    return Post(
      id: (json['id'] ?? 0).toString(),
      userName: json['userName'] ?? 'Unknown',
      role: json['userRole'] ?? 'User',
      avatarUrl: _buildImageUrl(json['userProfilePicture'] as String?),
      timeAgo: timeAgo,
      statusText: statusText,
      imageUrl: _buildImageUrl(json['postImage'] as String?),
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isBookmarked: false,
      caption: caption,
      tags: tags,
      hasRouteCard: hasRoute,
      fromLocation: from,
      toLocation: to,
      departureTime: json['travelTime'],
      contactNumber: json['userMobileNumber'],
    );
  }

  /// Calculate a human-readable "time ago" string from an ISO datetime
  static String _calculateTimeAgo(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }

  /// Build full image URL from backend relative path
  static String _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    // Already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Relative path from backend — prepend base URL
    return '${ApiConstants.baseUrl}$imagePath';
  }

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
