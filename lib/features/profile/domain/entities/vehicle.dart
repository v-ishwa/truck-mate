class Vehicle {
  final String id;
  final String tyreType; // e.g. "Container", "Open Body", etc.
  final int tyreCount;
  final String? vehicleNumber;
  final String? imageUrl;
  final String? driverName;
  final String? driverRating;
  final String? driverStatus;

  const Vehicle({
    required this.id,
    required this.tyreType,
    this.tyreCount = 0,
    this.vehicleNumber,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'tyreType': tyreType,
    'tyreCount': tyreCount,
    'vehicleNumber': vehicleNumber,
    'imageUrl': imageUrl,
    'driverName': driverName,
    'driverRating': driverRating,
    'driverStatus': driverStatus,
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String? ?? '',
    tyreType: json['tyreType'] as String? ?? '',
    tyreCount: (json['tyreCount'] as num?)?.toInt() ?? 0,
    vehicleNumber: json['vehicleNumber'] as String?,
    imageUrl: json['imageUrl'] as String?,
    driverName: json['driverName'] as String?,
    driverRating: json['driverRating'] as String?,
    driverStatus: json['driverStatus'] as String?,
  );
}
