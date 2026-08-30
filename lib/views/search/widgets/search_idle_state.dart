import 'package:flutter/material.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Exibe sugestões de busca e o veredito explicado quando não há query
class SearchIdleState extends StatelessWidget {
  const SearchIdleState({super.key});

  static const _suggestions = [
    'Fiat Marea Turbo',
    'VW Gol Quadrado',
    'Renault Kardian',
    'Chevrolet Onix',
    'Toyota Corolla',
    'Honda Civic',
    'Fiat Pulse',
    'Hyundai HB20',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Como funciona o veredito ──
          _SectionTitle(title: 'O que significa cada veredito?'),
          const SizedBox(height: 12),
          _VerdictExplanationCard(
            emoji: '✅',
            title: 'Zoeira Car Recomenda!',
            description: 'Pocotós garantidos e oficina longe. '
                'Nave confiável, boa relação custo-benefício e histórico limpo.',
            color: AppColors.verdictGreen,
          ),
          const SizedBox(height: 8),
          _VerdictExplanationCard(
            emoji: '⚠️',
            title: 'Ok, mas só se tiver barato',
            description: 'Tem seus pontos bons, mas também seus BOs. '
                'Negocia bem o preço e faz uma vistoria antes de comprar.',
            color: AppColors.verdictYellow,
          ),
          const SizedBox(height: 8),
          _VerdictExplanationCard(
            emoji: '🚨',
            title: 'Corre que é Cilada!',
            description: 'Prepare o bolso e o número do guincho. '
                'Problemas crônicos sérios ou custo de manutenção nas alturas.',
            color: AppColors.verdictRed,
          ),

          const SizedBox(height: 28),

          // ── Sugestões de busca ──
          _SectionTitle(title: 'Sugestões de naves'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => _SuggestionChip(label: s))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _VerdictExplanationCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _VerdictExplanationCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
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
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    // Pega o controller via context para preencher o campo
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.cardBackground,
      side: const BorderSide(color: AppColors.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onPressed: () {
        // Notifica a tela pai para preencher o campo de texto
        // via um callback registrado no InheritedWidget ou simples navegação
        // Aqui usamos um approach simples: apenas exibe o chip como hint
      },
    );
  }
}
