import 'package:flutter/material.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Badge visual do veredito zoeiro do veículo.
/// Parâmetro [large] exibe uma versão maior, usada na tela de detalhe.
class VerdictBadge extends StatelessWidget {
  final VehicleVerdict verdict;
  final bool large;

  const VerdictBadge({
    super.key,
    required this.verdict,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color(verdict);
    final emoji = verdict.emoji;
    final label = verdict.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: large ? 18 : 14),
          ),
          SizedBox(width: large ? 8 : 6),
          // Flexible + ellipsis para nunca estourar a largura do card
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: large ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _color(VehicleVerdict verdict) {
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
