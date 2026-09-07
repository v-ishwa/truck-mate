abstract class VehicleRepository {
  /// Saves a new vehicle and returns the saved vehicle's id.
  Future<String> addVehicle({
    required String bodyType,
    required int tyreCount,
    required String vehicleNumber,
    String? imageUrl,
  });
}
