import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Seção premium desbloqueada para assinantes da Capivara Completa.
class PremiumSection extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isLoadingFipe;
  final String? fipeError;
  final VoidCallback onRefreshFipe;
  final List<int> fipeYears;
  final int? selectedFipeYear;
  final String? fipeReference;
  final ValueChanged<int>? onSelectFipeYear;

  const PremiumSection({
    super.key,
    required this.vehicle,
    required this.isLoadingFipe,
    required this.onRefreshFipe,
    this.fipeError,
    this.fipeYears = const [],
    this.selectedFipeYear,
    this.fipeReference,
    this.onSelectFipeYear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge assinante ──
          _PremiumBadge(),

          const SizedBox(height: 20),

          // ── Tabela FIPE ──
          _FipeCard(
            vehicle: vehicle,
            isLoading: isLoadingFipe,
            error: fipeError,
            onRefresh: onRefreshFipe,
            years: fipeYears,
            selectedYear: selectedFipeYear,
            reference: fipeReference,
            onSelectYear: onSelectFipeYear,
          ),

          const SizedBox(height: 20),

          // ── Problemas Crônicos ──
          if (vehicle.chronicProblems != null &&
              vehicle.chronicProblems!.isNotEmpty)
            _PremiumInfoCard(
              icon: '🔧',
              title: 'Onde o bicho pega de verdade (Crônicos)',
              content: vehicle.chronicProblems!,
              accentColor: AppColors.verdictRed,
            ),

          const SizedBox(height: 14),

          // ── Cuidados ao Comprar / Checklist do Piloto ──
          if (vehicle.buyingCare != null && vehicle.buyingCare!.isNotEmpty)
            _PremiumInfoCard(
              icon: '🔍',
              title: 'Cuidados ao Comprar (Checklist do Piloto)',
              content: vehicle.buyingCare!,
              accentColor: AppColors.verdictYellow,
            ),

          const SizedBox(height: 14),

          // ── Opinião dos Donos / A Real de Quem Tem ──
          if (vehicle.ownersOpinion != null && vehicle.ownersOpinion!.isNotEmpty)
            _PremiumInfoCard(
              icon: '🗣️',
              title: 'Opinião dos Donos (A Real de Quem Tem)',
              content: vehicle.ownersOpinion!,
              accentColor: AppColors.primary,
            ),

          const SizedBox(height: 14),

          // ── Por que comprar ──
          if (vehicle.whyBuy != null && vehicle.whyBuy!.isNotEmpty)
            _PremiumInfoCard(
              icon: '✅',
              title: 'Por que comprar',
              content: vehicle.whyBuy!,
              accentColor: AppColors.verdictGreen,
            ),

          const SizedBox(height: 14),

          // ── Por que passar longe ──
          if (vehicle.whyAvoid != null && vehicle.whyAvoid!.isNotEmpty)
            _PremiumInfoCard(
              icon: '🚨',
              title: 'Por que passar longe',
              content: vehicle.whyAvoid!,
              accentColor: AppColors.verdictRed,
            ),

          const SizedBox(height: 14),

          // ── Ficha técnica ──
          if (vehicle.technicalSpecs != null &&
              vehicle.technicalSpecs!.isNotEmpty)
            _TechnicalSpecsCard(specs: vehicle.technicalSpecs!),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Badge de assinante premium
// ─────────────────────────────────────────────

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.black, size: 18),
          const SizedBox(width: 6),
          Text(
            'Capivara da sua nave puxada 🦫',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card da tabela FIPE
// ─────────────────────────────────────────────

class _FipeCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final List<int> years;
  final int? selectedYear;
  final String? reference;
  final ValueChanged<int>? onSelectYear;

  const _FipeCard({
    required this.vehicle,
    required this.isLoading,
    required this.onRefresh,
    this.error,
    this.years = const [],
    this.selectedYear,
    this.reference,
    this.onSelectYear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Tabela FIPE',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              // Botão atualizar
              GestureDetector(
                onTap: isLoading ? null : onRefresh,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded,
                          color: AppColors.primary, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Seletor de ano do veículo na tabela FIPE
          if (years.isNotEmpty) ...[
            Text(
              'Ano do veículo:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: years.map((y) {
                final selected = y == selectedYear;
                return ChoiceChip(
                  label: Text(
                    y == 0 ? 'Zero KM' : '$y',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.black : AppColors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.cardBackground,
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: onSelectYear == null
                      ? null
                      : (_) => onSelectYear!(y),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (error != null)
            Text(error!,
                style: TextStyle(color: AppColors.verdictRed, fontSize: 12))
          else if (vehicle.fipePrice != null) ...[
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(vehicle.fipePrice),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (reference != null && reference!.isNotEmpty)
              Text(
                'Referência: $reference',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else if (vehicle.fipeUpdatedAt != null)
              Text(
                'Atualizado em ${DateFormat('dd/MM/yyyy').format(vehicle.fipeUpdatedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ] else
            Text(
              'Toque em atualizar para buscar o preço FIPE atual',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

          if (vehicle.fipeCode != null && vehicle.fipeCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Código FIPE: ${vehicle.fipeCode}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card genérico de info premium
// ─────────────────────────────────────────────

class _PremiumInfoCard extends StatefulWidget {
  final String icon;
  final String title;
  final String content;
  final Color accentColor;

  const _PremiumInfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.accentColor,
  });

  @override
  State<_PremiumInfoCard> createState() => _PremiumInfoCardState();
}

class _PremiumInfoCardState extends State<_PremiumInfoCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header (clicável para colapsar)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: _expanded ? Radius.zero : const Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card de ficha técnica
// ─────────────────────────────────────────────

class _TechnicalSpecsCard extends StatelessWidget {
  final String specs;

  const _TechnicalSpecsCard({required this.specs});

  @override
  Widget build(BuildContext context) {
    // Specs armazenadas como "Chave: Valor\nChave: Valor\n..."
    final lines = specs
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'Ficha Técnica',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.cardBorder, height: 1),
          ...lines.asMap().entries.map((entry) {
            final parts = entry.value.split(':');
            final key =
                parts.isNotEmpty ? parts.first.trim() : entry.value.trim();
            final value = parts.length > 1
                ? parts.sublist(1).join(':').trim()
                : '';

            return Container(
              decoration: BoxDecoration(
                color: entry.key.isEven
                    ? Colors.transparent
                    : AppColors.surface.withOpacity(0.5),
                borderRadius: entry.key == lines.length - 1
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(14))
                    : null,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
