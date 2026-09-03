import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/services/vehicle_service.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/verdict_badge.dart';

// ─────────────────────────────────────────────────────────
// Modelo de categoria
// ─────────────────────────────────────────────────────────
class VehicleCategory {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VehicleVerdict verdict;

  const VehicleCategory({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.verdict,
  });
}

const _categories = [
  VehicleCategory(
    id: 'recommended',
    emoji: '✅',
    title: 'Zoeira Car Recomenda!',
    subtitle: 'Pocotós garantidos e oficina longe',
    color: AppColors.verdictGreen,
    verdict: VehicleVerdict.recommended,
  ),
  VehicleCategory(
    id: 'ok_if_cheap',
    emoji: '⚠️',
    title: 'Ok se tiver barato',
    subtitle: 'Negocia bem antes de fechar',
    color: AppColors.verdictYellow,
    verdict: VehicleVerdict.okIfCheap,
  ),
  VehicleCategory(
    id: 'run_away',
    emoji: '🚨',
    title: 'Corre que é Cilada!',
    subtitle: 'Prepare o guincho e o bolso',
    color: AppColors.verdictRed,
    verdict: VehicleVerdict.runAway,
  ),
  VehicleCategory(
    id: 'exclusive',
    emoji: '👑',
    title: 'Exclusivo pra Poucos',
    subtitle: 'Supercarro — só se o bolso aguenta',
    color: AppColors.verdictPurple,
    verdict: VehicleVerdict.exclusive,
  ),
  VehicleCategory(
    id: 'no_history',
    emoji: '🔵',
    title: 'Sem Histórico',
    subtitle: 'Recém-lançado — aguarda histórico',
    color: AppColors.verdictBlue,
    verdict: VehicleVerdict.noHistory,
  ),
];

// ─────────────────────────────────────────────────────────
// Tela principal de categorias
// ─────────────────────────────────────────────────────────
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Categorias',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return _CategoryCard(
            category: cat,
            onTap: () => context.push('/categorias/${cat.id}'),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final VehicleCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: category.color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: category.color),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tela de lista de carros por categoria
// ─────────────────────────────────────────────────────────
class CategoryVehiclesScreen extends StatefulWidget {
  final String categoryId;

  const CategoryVehiclesScreen({super.key, required this.categoryId});

  @override
  State<CategoryVehiclesScreen> createState() => _CategoryVehiclesScreenState();
}

class _CategoryVehiclesScreenState extends State<CategoryVehiclesScreen> {
  final _service = VehicleService();
  List<VehicleModel>? _vehicles;
  String? _error;

  VehicleCategory get _category =>
      _categories.firstWhere((c) => c.id == widget.categoryId,
          orElse: () => _categories.first);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.getVehiclesByVerdict(widget.categoryId);
      if (mounted) setState(() => _vehicles = all);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = _category;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cat.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cat.color,
                      fontWeight: FontWeight.w800,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Deu BO!', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _load, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      );
    }

    if (_vehicles == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_vehicles!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚗', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Nenhum carro nessa categoria ainda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final v = _vehicles![i];
        return _VehicleListItem(
          vehicle: v,
          onTap: () => context.push('/veiculo/${v.id}'),
        );
      },
    );
  }
}

class _VehicleListItem extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const _VehicleListItem({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: SizedBox(
                width: 88,
                height: 88,
                child: vehicle.thumbnailUrl.isNotEmpty
                    ? Image.asset(
                        vehicle.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _FallbackThumb(vehicle: vehicle),
                      )
                    : _FallbackThumb(vehicle: vehicle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.version,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  VerdictBadge(verdict: vehicle.verdict),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  final VehicleModel vehicle;
  const _FallbackThumb({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(
          vehicle.brand.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
