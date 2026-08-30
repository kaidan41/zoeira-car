import 'package:flutter/material.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/verdict_badge.dart';

/// Seção pública (gratuita) da tela de detalhe do veículo.
/// Exibe: nome, veredito, resumo zoeiro e dados básicos.
class FreeSection extends StatelessWidget {
  final VehicleModel vehicle;

  const FreeSection({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nome completo ──
          Text(
            vehicle.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
          ),

          const SizedBox(height: 6),

          // ── Anos + faixa de preço ──
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_rounded,
                label: vehicle.yearsFormatted,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.attach_money_rounded,
                label: vehicle.priceRange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Veredito badge grande ──
          VerdictBadge(verdict: vehicle.verdict, large: true),

          const SizedBox(height: 12),

          // ── Resumo zoeiro ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _verdictColor(vehicle.verdict).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _verdictColor(vehicle.verdict).withOpacity(0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.verdict.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.verdict.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: _verdictColor(vehicle.verdict),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.verdict.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                      if (vehicle.verdictSummary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.cardBorder, height: 1),
                        const SizedBox(height: 8),
                        Text(
                          '"${vehicle.verdictSummary}"',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Divisor com label de conteúdo premium ──
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.cardBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ANÁLISE COMPLETA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.cardBorder)),
            ],
          ),

          const SizedBox(height: 16),
        ],
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
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
