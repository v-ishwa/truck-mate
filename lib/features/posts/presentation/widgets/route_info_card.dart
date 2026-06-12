import 'package:flutter/material.dart';

class RouteInfoCard extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final String departureTime;
  final VoidCallback onCallPressed;

  const RouteInfoCard({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.departureTime,
    required this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-specific colors
    final cardBgColor = isDark ? const Color(0xFF161616) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;
    final dividerColor = isDark ? const Color(0xFF262626) : Colors.grey.shade300;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final secondaryTextColor = isDark ? const Color(0xFFA8A8A8) : Colors.grey.shade600;
    final iconColor = isDark ? Colors.white70 : const Color(0xFF1C1C1C);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // From Location
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fromLocation,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            VerticalDivider(color: dividerColor, thickness: 1, width: 16),
            
            // To Location
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          toLocation,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            VerticalDivider(color: dividerColor, thickness: 1, width: 16),
            
            // Departure Time
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 18, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          departureTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 4),

            // Call Owner Button
            GestureDetector(
              onTap: onCallPressed,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E88E5) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    const Text(
                      'Call Owner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
