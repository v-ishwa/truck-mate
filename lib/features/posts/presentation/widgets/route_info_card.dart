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

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDark ? const Color(0xFFB0B8D0) : const Color(0xFF6B7280);

    // Parse departureTime — expected format: "20 Jan 2026 08:30 AM" or similar
    // We'll split on first space-separated token groups: date part vs time part
    String datePart = '';
    String timePart = '';
    final parts = departureTime.trim().split(' ');
    if (parts.length >= 4) {
      // e.g. "20 Jan 2026 08:30 AM" → date = "20 Jan 2026", time = "08:30 AM"
      datePart = '${parts[0]} ${parts[1]} ${parts[2]}';
      timePart = parts.sublist(3).join(' ');
    } else if (parts.length >= 2) {
      datePart = parts[0];
      timePart = parts.sublist(1).join(' ');
    } else {
      timePart = departureTime;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route row: From → To
        Row(
          children: [
            Text(
              fromLocation,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: isDark ? const Color(0xFF3D6CBF) : const Color(0xFF1565C0),
              ),
            ),
            Text(
              toLocation,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Date, Time, Price row
        Row(
          children: [
            // Date in green
            if (datePart.isNotEmpty) ...[
              Text(
                datePart,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Time
            if (timePart.isNotEmpty) ...[
              Text(
                timePart,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

