import 'package:flutter/material.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/vehicle_illustration.dart';
import 'package:zoeira_car/widgets/verdict_badge.dart';

class SearchResultsList extends StatelessWidget {
  final List<VehicleModel> results;
  final void Function(String vehicleId) onVehicleTap;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onVehicleTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 220 + index * 35),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        ),
        child: _VehicleResultCard(
          vehicle: results[index],
          onTap: () => onVehicleTap(results[index].id),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card de resultado de busca
// ─────────────────────────────────────────────

class _VehicleResultCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const _VehicleResultCard({
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final verdictColor = _verdictColor(vehicle.verdict);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: verdictColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ── Illustration (Hero leve) ──
            Hero(
              tag: 'vehicle-${vehicle.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
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
            ),

            // ── Infos ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Marca + modelo
                    Text(
                      vehicle.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Anos
                    Text(
                      vehicle.yearsFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Veredito badge
                    VerdictBadge(verdict: vehicle.verdict),

                    const SizedBox(height: 6),

                    // Resumo zoeiro
                    Text(
                      vehicle.verdictSummary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // ── Seta ──
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                color: verdictColor,
                size: 24,
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
      case VehicleVerdict.noHistory:
        return AppColors.verdictBlue;
    }
  }
}
