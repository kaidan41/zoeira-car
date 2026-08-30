import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:zoeira_car/models/subscription_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';

class PlanCard extends StatelessWidget {
  final bool isSubscriber;
  final bool isLoading;
  final ProductDetails? product;
  final VoidCallback onPurchase;

  const PlanCard({
    super.key,
    required this.isSubscriber,
    required this.isLoading,
    required this.onPurchase,
    this.product,
  });

  @override
  Widget build(BuildContext context) {
    // Preço real da Play Store, ou fallback
    final priceDisplay = product?.price ?? SubscriptionPlan.price;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Preço ──
          Text(
            priceDisplay,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),

          const SizedBox(height: 4),

          Text(
            'Cobrança mensal recorrente via Google Play',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),

          const SizedBox(height: 20),

          // ── Botão de ação ──
          SizedBox(
            width: double.infinity,
            child: isSubscriber
                ? _AlreadySubscriberButton(context: context)
                : _PurchaseButton(
                    isLoading: isLoading,
                    onTap: onPurchase,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _PurchaseButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: Colors.black45,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          : Text(
              'Assinar agora — Sem fidelidade 🚀',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
    );
  }
}

class _AlreadySubscriberButton extends StatelessWidget {
  final BuildContext context;
  const _AlreadySubscriberButton({required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.black, size: 20),
          const SizedBox(width: 8),
          Text(
            'Plano ativo! Tá na nave 🚀',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
