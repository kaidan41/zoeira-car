import 'package:flutter/material.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Widget de estado de erro genérico com botão de retry.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
    this.retryLabel = 'Tentar de novo',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone zoeiro
            const Text('💥', style: TextStyle(fontSize: 56)),

            const SizedBox(height: 16),

            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),

            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
