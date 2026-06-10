import 'package:flutter/material.dart';

class FallbackPostsView extends StatelessWidget {
  final VoidCallback onUploadPressed;

  const FallbackPostsView({
    super.key,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant dashed border or circle around a photo icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF8E8E8E),
              size: 36,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Posts Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share images of your trucks, active deliveries, and fleet milestones with the TruckMate network.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF707070),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Clean custom button to simulate uploading a post
          TextButton.icon(
            onPressed: onUploadPressed,
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Upload First Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0095F6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF0095F6).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
