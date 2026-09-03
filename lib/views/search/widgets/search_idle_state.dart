import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Exibe sugestões de busca e o veredito explicado quando não há query
class SearchIdleState extends StatelessWidget {
  final void Function(String query)? onSuggestionTap;

  const SearchIdleState({super.key, this.onSuggestionTap});

  static const _suggestions = [
    'Fiat Marea Turbo',
    'Volkswagen Gol Quadrado',
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
          // ── Como funciona o veredito (clicável → categorias) ──
          _SectionTitle(title: 'O que significa cada veredito?'),
          const SizedBox(height: 12),
          _VerdictExplanationCard(
            emoji: '✅',
            title: 'Zoeira Car Recomenda!',
            description: 'Pocotós garantidos e oficina longe. '
                'Nave confiável, boa relação custo-benefício e histórico limpo.',
            color: AppColors.verdictGreen,
            categoryId: 'recommended',
          ),
          const SizedBox(height: 8),
          _VerdictExplanationCard(
            emoji: '⚠️',
            title: 'Ok, mas só se tiver barato',
            description: 'Tem seus pontos bons, mas também seus BOs. '
                'Negocia bem o preço e faz uma vistoria antes de comprar.',
            color: AppColors.verdictYellow,
            categoryId: 'ok_if_cheap',
          ),
          const SizedBox(height: 8),
          _VerdictExplanationCard(
            emoji: '👑',
            title: 'Exclusivo pra Poucos!',
            description: 'Só se o bolso aguenta o tranco. '
                'Supercarro/hipercarro com manutenção e seguro nas alturas.',
            color: AppColors.verdictPurple,
            categoryId: 'exclusive',
          ),
          const SizedBox(height: 8),
          _VerdictExplanationCard(
            emoji: '🔵',
            title: 'Sem Histórico',
            description: 'Recém-lançado, ainda sem dados de oficina. '
                'Aguarde mais histórico ou faça vistoria caprichada.',
            color: AppColors.verdictBlue,
            categoryId: 'no_history',
          ),
          const SizedBox(height: 8),
          _VerdictExplanationCard(
            emoji: '🚨',
            title: 'Corre que é Cilada!',
            description: 'Prepare o bolso e o número do guincho. '
                'Problemas crônicos sérios ou custo de manutenção nas alturas.',
            color: AppColors.verdictRed,
            categoryId: 'run_away',
          ),

          const SizedBox(height: 28),

          // ── Sugestões de busca ──
          _SectionTitle(title: 'Sugestões de naves'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => _SuggestionChip(
                      label: s,
                      onTap: () => onSuggestionTap?.call(s),
                    ))
                .toList(),
          ),

          const SizedBox(height: 32),

          // ── Solicitar inclusão de carro ──
          _SectionTitle(title: 'Não achou sua nave?'),
          const SizedBox(height: 12),
          _RequestCarCard(onSuggestionTap: onSuggestionTap),
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
  final String? categoryId;

  const _VerdictExplanationCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final categoryId = this.categoryId;

    return Material(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: categoryId == null
            ? null
            : () => context.push('/categorias/$categoryId'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
              if (categoryId != null) ...[const SizedBox(width: 8), Icon(
                Icons.chevron_right_rounded,
                color: color,
              )],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SuggestionChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
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
      onPressed: onTap,
    );
  }
}

class _RequestCarCard extends StatelessWidget {
  final void Function(String query)? onSuggestionTap;
  const _RequestCarCard({this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚗', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Solicitar inclusão de nave',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Não encontrou o carro que procura? Manda a solicitação pra gente catalogar!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'zoeiracarcontato@gmail.com',
                  queryParameters: {
                    'subject': 'Solicitar inclusão de nave no Zoeira Car',
                    'body':
                        'Olá, gostaria de solicitar a inclusão do seguinte veículo:\n\nMarca: \nModelo: \nAno: \n\nObrigado!',
                  },
                );
                launchUrl(uri);
              },
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Enviar solicitação'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
