import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zoeira_car/models/subscription_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Exibido quando o usuário já tem assinatura ativa.
class ActiveSubscriptionCard extends StatelessWidget {
  final SubscriptionModel subscription;

  const ActiveSubscriptionCard({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.verdictGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.verdictGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.verdictGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      'ATIVO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subscription.status.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.verdictGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Datas
          if (subscription.startDate != null)
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Início',
              value: DateFormat('dd/MM/yyyy').format(subscription.startDate!),
            ),

          if (subscription.expiryDate != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.event_rounded,
              label: 'Próxima cobrança',
              value: DateFormat('dd/MM/yyyy').format(subscription.expiryDate!),
              highlight: subscription.expiringSoon,
            ),
          ],

          const SizedBox(height: 8),

          _InfoRow(
            icon: Icons.autorenew_rounded,
            label: 'Renovação automática',
            value: subscription.autoRenewing ? 'Sim' : 'Não',
          ),

          // Aviso de vencimento próximo
          if (subscription.expiringSoon) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.verdictYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.verdictYellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.verdictYellow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sua assinatura vence em ${subscription.daysRemaining} dia(s)!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.verdictYellow,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Link para gerenciar na Play Store
          OutlinedButton.icon(
            onPressed: () {
              // Abre as assinaturas do Google Play
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Gerenciar na Play Store'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.verdictGreen,
              side: BorderSide(
                  color: AppColors.verdictGreen.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    highlight ? AppColors.verdictYellow : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
