import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/subscription_controller.dart';
import 'package:zoeira_car/models/subscription_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/views/subscription/widgets/plan_card.dart';
import 'package:zoeira_car/views/subscription/widgets/active_subscription_card.dart';
import 'package:zoeira_car/views/subscription/widgets/benefits_list.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Garante que mensagens antigas não ficam na tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().clearMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Puxe agora a Capivara da Sua Nave',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        centerTitle: true,
      ),
      body: Consumer<SubscriptionController>(
        builder: (context, ctrl, _) {
          // Exibe feedback de erro ou sucesso
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleMessages(context, ctrl);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header zoeiro ──
                _buildHeader(context),

                const SizedBox(height: 28),

                // ── Se já é assinante: card de status ──
                if (ctrl.isSubscriber && ctrl.subscription != null) ...[
                  ActiveSubscriptionCard(subscription: ctrl.subscription!),
                  const SizedBox(height: 24),
                ],

                // ── Lista de benefícios ──
                const BenefitsList(),

                const SizedBox(height: 16),

                // ── Alternativa avulsa ──
                if (!ctrl.isSubscriber)
                  _buildSingleOption(context),

                const SizedBox(height: 28),

                // ── Card do plano ──
                PlanCard(
                  isSubscriber: ctrl.isSubscriber,
                  isLoading: ctrl.isPurchasing,
                  product: ctrl.product,
                  onPurchase: ctrl.purchase,
                ),

                const SizedBox(height: 16),

                // ── Restaurar compras ──
                if (!ctrl.isSubscriber)
                  _buildRestoreButton(context, ctrl),

                const SizedBox(height: 28),

                // ── Rodapé legal ──
                _buildLegalFooter(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Ícone animado
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('🦫', style: TextStyle(fontSize: 44)),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          SubscriptionPlan.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Chega de comprar gato por lebre!\nVeja tudo sobre qualquer nave antes de abrir a carteira.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSingleOption(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prefere pagar por carro?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dá pra desbloquear 1 nave por ${ConsultationPlan.price}. Direto na tela de cada carro!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(
      BuildContext context, SubscriptionController ctrl) {
    return TextButton.icon(
      onPressed: ctrl.isRestoring ? null : ctrl.restorePurchases,
      icon: ctrl.isRestoring
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            )
          : const Icon(Icons.restore_rounded,
              color: AppColors.textSecondary, size: 18),
      label: Text(
        ctrl.isRestoring ? 'Restaurando...' : 'Restaurar compra anterior',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildLegalFooter(BuildContext context) {
    final productPrice = context.read<SubscriptionController>().product?.price ??
        SubscriptionPlan.price;

    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary.withOpacity(0.6),
          height: 1.5,
          fontSize: 11,
        );

    return Column(
      children: [
        Text(
          '• Cobrança via Google Play de $productPrice',
          style: style,
          textAlign: TextAlign.center,
        ),
        Text(
          '• A assinatura renova automaticamente. Cancele quando quiser.',
          style: style,
          textAlign: TextAlign.center,
        ),
        Text(
          '• Cancelamento não gera reembolso do período já pago.',
          style: style,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Política de Privacidade',
                  style: style?.copyWith(
                      decoration: TextDecoration.underline,
                      color: AppColors.textSecondary)),
            ),
            Text(' · ', style: style),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Termos de Uso',
                  style: style?.copyWith(
                      decoration: TextDecoration.underline,
                      color: AppColors.textSecondary)),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMessages(BuildContext context, SubscriptionController ctrl) {
    if (ctrl.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.successMessage!),
          backgroundColor: AppColors.verdictGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      ctrl.clearMessages();
    } else if (ctrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.errorMessage!),
          backgroundColor: AppColors.verdictRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      ctrl.clearMessages();
    }
  }
}
