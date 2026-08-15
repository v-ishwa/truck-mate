class Vehicle {
  final String id;
  final String tyreType;   // "6 Tyre · Container", "4 Tyre · Mini (Dost)", etc.
  final int tyreCount;     // 4, 6, 8, 10, 12
  final String? imageUrl;  // null = show illustration placeholder
  final String? driverName;   // null = no driver assigned
  final String? driverRating; // e.g. "4.8"
  final String? driverStatus; // "On duty" | "Off duty"

  const Vehicle({
    required this.id,
    required this.tyreType,
    required this.tyreCount,
    this.imageUrl,
    this.driverName,
    this.driverRating,
    this.driverStatus,
  });

  bool get hasDriver => driverName != null && driverName!.isNotEmpty;

  /// Initials from driver name, e.g. "Ravi Kumar" → "RK"
  String get driverInitials {
    if (!hasDriver) return '';
    final parts = driverName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
