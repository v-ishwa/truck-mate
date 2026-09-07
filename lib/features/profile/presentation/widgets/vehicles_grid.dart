import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/vehicle.dart';
import 'package:truck_mate/core/widgets/truck_illustration.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock vehicle list — kept as reference if needed.
// ─────────────────────────────────────────────────────────────────────────────
final List<Vehicle> kMockVehicles = [
  const Vehicle(
    id: 'v1',
    tyreType: 'Container',
    tyreCount: 6,
    vehicleNumber: 'TN 45 AB 1234',
    driverName: 'Ravi Kumar',
    driverRating: '4.8',
    driverStatus: 'On duty',
  ),
  const Vehicle(
    id: 'v2',
    tyreType: 'Open Body',
    tyreCount: 10,
    vehicleNumber: 'TN 45 CD 5678',
    driverName: 'Murugan P.',
    driverRating: '4.6',
    driverStatus: 'On duty',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main grid widget
// ─────────────────────────────────────────────────────────────────────────────
class VehiclesGrid extends StatelessWidget {
  final List<Vehicle>? vehicles;
  final Function(Vehicle)? onVehicleTap;
  final Function(Vehicle)? onVehicleDelete;

  const VehiclesGrid({
    super.key,
    this.vehicles,
    this.onVehicleTap,
    this.onVehicleDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? Colors.black : const Color(0xFFEBF3FF);
    final list = vehicles ?? const [];

    if (list.isEmpty) {
      return Container(
        color: pageBg,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEBF3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Color(0xFF1565C0),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Vehicles Added Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F2C59),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "Add vehicle" above to add your first vehicle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            onDelete: onVehicleDelete != null
                ? () => onVehicleDelete!(list[index])
                : null,
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
  final VoidCallback? onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onTap,
    this.onDelete,
  });

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
            // ── Tyre type label & delete button ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
              child: Row(
                children: [
                  Expanded(
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
                  if (onDelete != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                ],
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
                      child: _buildVehicleImage(truckColor),
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
                          vehicle.vehicleNumber != null && vehicle.vehicleNumber!.isNotEmpty
                              ? vehicle.vehicleNumber!
                              : 'Tap + to add driver',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: vehicle.vehicleNumber != null && vehicle.vehicleNumber!.isNotEmpty
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark
                                ? const Color(0xFFB0B8D0)
                                : const Color(0xFF6B7280),
                            letterSpacing: vehicle.vehicleNumber != null && vehicle.vehicleNumber!.isNotEmpty ? 0.3 : 0,
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
    );
  }

  Widget _buildVehicleImage(Color truckColor) {
    if (vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty) {
      if (vehicle.imageUrl!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            vehicle.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _TruckPlaceholder(
              tyreCount: vehicle.tyreCount,
              color: truckColor,
            ),
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(vehicle.imageUrl!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _TruckPlaceholder(
              tyreCount: vehicle.tyreCount,
              color: truckColor,
            ),
          ),
        );
      }
    }
    return _TruckPlaceholder(
      tyreCount: vehicle.tyreCount,
      color: truckColor,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Truck line-art placeholder (centred inside the blue card area)
// ─────────────────────────────────────────────────────────────────────────────
class _TruckPlaceholder extends StatelessWidget {
  final int tyreCount;
  final Color color;

  const _TruckPlaceholder({
    required this.tyreCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TruckIllustration(
        tyreCount: tyreCount,
        color: color,
        size: const Size(110, 48),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driver badge with initials (e.g. "RK", "MP")
// ─────────────────────────────────────────────────────────────────────────────
class _DriverBadge extends StatelessWidget {
  final String initials;

  const _DriverBadge({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFF0F2C59),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orange "+" badge when no driver is assigned
// ─────────────────────────────────────────────────────────────────────────────
class _AddDriverBadge extends StatelessWidget {
  const _AddDriverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
