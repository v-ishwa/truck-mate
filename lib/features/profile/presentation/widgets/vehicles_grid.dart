import 'package:flutter/material.dart';
import '../../domain/entities/vehicle.dart';
import 'package:truck_mate/core/widgets/truck_illustration.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock vehicle list — matches the screenshot.
// TODO: Replace with real API data when backend is ready.
// ─────────────────────────────────────────────────────────────────────────────
final List<Vehicle> kMockVehicles = [
  const Vehicle(
    id: 'v1',
    tyreType: '6 Tyre · Container',
    tyreCount: 6,
    driverName: 'Ravi Kumar',
    driverRating: '4.8',
    driverStatus: 'On duty',
  ),
  const Vehicle(
    id: 'v2',
    tyreType: '10 Tyre · Open Body',
    tyreCount: 10,
    driverName: 'Murugan P.',
    driverRating: '4.6',
    driverStatus: 'On duty',
  ),
  const Vehicle(
    id: 'v3',
    tyreType: '4 Tyre · Mini (Dost)',
    tyreCount: 4,
  ),
  const Vehicle(
    id: 'v4',
    tyreType: '6 Tyre · Container',
    tyreCount: 6,
  ),
  const Vehicle(
    id: 'v5',
    tyreType: '8 Tyre · Tanker',
    tyreCount: 8,
    driverName: 'Selvam V.',
    driverRating: '4.5',
    driverStatus: 'On duty',
  ),
  const Vehicle(
    id: 'v6',
    tyreType: '4 Tyre · Mini (Dost)',
    tyreCount: 4,
    driverName: 'Arun K.',
    driverRating: '4.3',
    driverStatus: 'Off duty',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main grid widget
// ─────────────────────────────────────────────────────────────────────────────
class VehiclesGrid extends StatelessWidget {
  final List<Vehicle>? vehicles; // null → use mock data
  final Function(Vehicle)? onVehicleTap;

  const VehiclesGrid({
    super.key,
    this.vehicles,
    this.onVehicleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? Colors.black : const Color(0xFFEBF3FF);
    final list = vehicles ?? kMockVehicles;

    return Container(
      color: pageBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, index) {
          return _VehicleCard(
            vehicle: list[index],
            onTap: () => onVehicleTap?.call(list[index]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual vehicle card
// ─────────────────────────────────────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final labelColor =
        isDark ? const Color(0xFFB0B8D0) : const Color(0xFF6B7280);
    final truckBg =
        isDark ? const Color(0xFF0F1C3F) : const Color(0xFFE8F0FE);
    final truckColor =
        isDark ? const Color(0xFF3D6CBF) : const Color(0xFF1565C0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFF1A3A6B).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tyre type label ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(
                vehicle.tyreType,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Vehicle image / illustration area ─────────────────
            Expanded(
              child: Stack(
                children: [
                  // Image or illustration
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: truckBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: vehicle.imageUrl != null &&
                              vehicle.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                vehicle.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    _TruckPlaceholder(
                                  tyreCount: vehicle.tyreCount,
                                  color: truckColor,
                                ),
                              ),
                            )
                          : _TruckPlaceholder(
                              tyreCount: vehicle.tyreCount,
                              color: truckColor,
                            ),
                    ),
                  ),

                  // Driver badge (top-right corner of the illustration box)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: vehicle.hasDriver
                        ? _DriverBadge(initials: vehicle.driverInitials)
                        : const _AddDriverBadge(),
                  ),
                ],
              ),
            ),

            // ── Driver info row ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
              child: vehicle.hasDriver
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.driverName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${vehicle.driverStatus ?? "On duty"} · ${vehicle.driverRating ?? "-"} rating',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFFB0B8D0)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No driver assigned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          'Tap + to add driver',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFFB0B8D0)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Truck line-art placeholder (centred inside the blue card area)
// ─────────────────────────────────────────────────────────────────────────────
class _TruckPlaceholder extends StatelessWidget {
  final int tyreCount;
  final Color color;
  const _TruckPlaceholder({required this.tyreCount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TruckIllustration(
        tyreCount: tyreCount,
        color: color,
        size: const Size(130, 55),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driver badge — blue circle with initials
// ─────────────────────────────────────────────────────────────────────────────
class _DriverBadge extends StatelessWidget {
  final String initials;
  const _DriverBadge({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add-driver badge — amber circle with + icon
// ─────────────────────────────────────────────────────────────────────────────
class _AddDriverBadge extends StatelessWidget {
  const _AddDriverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 18),
    );
  }
}
