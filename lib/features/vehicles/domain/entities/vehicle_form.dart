/// Represents the data submitted by the 'Add Vehicle' form.
class VehicleForm {
  final String bodyType;
  final int tyreCount;
  final String vehicleNumber;
  final String? imageUrl;

  const VehicleForm({
    required this.bodyType,
    this.tyreCount = 0,
    required this.vehicleNumber,
    this.imageUrl,
  });

  /// Human-readable label
  String get tyreTypeLabel => tyreCount > 0 ? '$tyreCount Tyre - $bodyType' : bodyType;
}
