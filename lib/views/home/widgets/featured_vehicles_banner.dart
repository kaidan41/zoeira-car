import 'package:flutter/material.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/vehicle_illustration.dart';

class FeaturedVehiclesBanner extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final void Function(String vehicleId) onVehicleTap;

  const FeaturedVehiclesBanner({
    super.key,
    required this.vehicles,
    required this.onVehicleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Naves em destaque 🚗',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 280 + index * 45),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(12 * (1 - value), 0),
                  child: child,
                ),
              ),
              child: _VehicleChip(
                vehicle: vehicles[index],
                onTap: () => onVehicleTap(vehicles[index].id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const _VehicleChip({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final verdictColor = _verdictColor(vehicle.verdict);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: verdictColor.withOpacity(0.5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration (imagem IA se houver)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 85,
                width: double.infinity,
                child: vehicle.thumbnailUrl.isNotEmpty
                    ? (vehicle.thumbnailUrl.startsWith('assets/')
                        ? Image.asset(
                            vehicle.thumbnailUrl,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            vehicle.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => VehicleIllustration(
                              brand: vehicle.brand,
                              bodyType: vehicle.bodyType,
                            ),
                          ))
                    : VehicleIllustration(
                        brand: vehicle.brand,
                        bodyType: vehicle.bodyType,
                      ),
              ),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.model,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Badge veredito
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: verdictColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehicle.verdict.emoji,
                      style: const TextStyle(fontSize: 12),
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

  Color _verdictColor(VehicleVerdict verdict) {
    switch (verdict) {
      case VehicleVerdict.recommended:
        return AppColors.verdictGreen;
      case VehicleVerdict.okIfCheap:
        return AppColors.verdictYellow;
      case VehicleVerdict.runAway:
        return AppColors.verdictRed;
      case VehicleVerdict.exclusive:
        return AppColors.verdictPurple;
    }
  }
}
