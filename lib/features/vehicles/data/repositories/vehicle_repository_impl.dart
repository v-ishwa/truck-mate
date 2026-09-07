import '../../domain/repositories/vehicle_repository.dart';

/// Stub implementation — wire to a real API when backend is ready.
class VehicleRepositoryImpl implements VehicleRepository {
  @override
  Future<String> addVehicle({
    required String bodyType,
    required int tyreCount,
    required String vehicleNumber,
    String? imageUrl,
  }) async {
    // TODO: POST to /api/vehicles with auth token
    await Future.delayed(const Duration(milliseconds: 500));
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
