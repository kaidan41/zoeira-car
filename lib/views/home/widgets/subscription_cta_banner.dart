import 'package:flutter/material.dart';
import 'package:zoeira_car/theme/app_colors.dart';

class SubscriptionCtaBanner extends StatelessWidget {
  final VoidCallback onTap;

  const SubscriptionCtaBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🦫', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puxe agora a Capivara\nda Sua Nave!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Veja o raio-x completo de qualquer nave por só R\$ 9,90/mês!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                ],
              ),
            ),

            // Seta
            const Icon(Icons.chevron_right_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
