import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/vehicle_detail_controller.dart';
import 'package:zoeira_car/controllers/subscription_controller.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/error_state_widget.dart';
import 'package:zoeira_car/widgets/vehicle_illustration.dart';
import 'package:zoeira_car/views/vehicle_detail/widgets/free_section.dart';
import 'package:zoeira_car/views/vehicle_detail/widgets/premium_section.dart';
import 'package:zoeira_car/views/vehicle_detail/widgets/paywall_card.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late final VehicleDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VehicleDetailController(vehicleId: widget.vehicleId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<VehicleDetailController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: _buildBody(context, ctrl),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, VehicleDetailController ctrl) {
    if (ctrl.isLoading) return _LoadingSkeleton();

    if (ctrl.hasError) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: BackButton(color: AppColors.textPrimary),
          elevation: 0,
        ),
        backgroundColor: AppColors.background,
        body: ErrorStateWidget(
          message: 'Não conseguimos carregar essa nave 😬',
          detail: ctrl.errorMessage,
          onRetry: ctrl.load,
        ),
      );
    }

    if (!ctrl.isLoaded || ctrl.vehicle == null) {
      return const SizedBox.shrink();
    }

    final vehicle = ctrl.vehicle!;

    return Consumer<SubscriptionController>(
      builder: (context, subCtrl, _) {
        final canView = subCtrl.isUnlocked(vehicle.id);

        return CustomScrollView(
          slivers: [
            // ── Hero com imagem + app bar ──
            _buildSliverAppBar(context, vehicle),

            // ── Veredito + dados básicos (FREE) ──
            SliverToBoxAdapter(
              child: FreeSection(vehicle: vehicle),
            ),

            // ── Conteúdo premium ou paywall ──
            SliverToBoxAdapter(
              child: canView
                  ? PremiumSection(
                      vehicle: vehicle,
                      isLoadingFipe: ctrl.loadingFipe,
                      fipeError: ctrl.fipeError,
                      onRefreshFipe: ctrl.refreshFipePrice,
                    )
                  : PaywallCard(
                      isCreditUnlocking: subCtrl.isCreditUnlocking,
                      isConsultaPurchasing: subCtrl.isConsultaPurchasing,
                      credits: subCtrl.credits,
                      onUnlockSingle: () => _unlockSingle(subCtrl, vehicle),
                      onSubscribe: () =>
                          context.push(AppRoutes.subscription),
                    ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        );
      },
    );
  }

  Future<void> _unlockSingle(
      SubscriptionController sub, VehicleModel vehicle) async {
    final ok = await sub.unlockOne(vehicle.id);
    if (!mounted) return;
    if (!ok) {
      _showSnack(
        context,
        sub.errorMessage ?? 'Iniciando compra...',
        false,
      );
    }
  }

  void _showSnack(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? AppColors.verdictGreen : AppColors.verdictRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, VehicleModel vehicle) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem do veículo (IA gerada) ou ilustração vetorial
            Hero(
              tag: 'vehicle-${vehicle.id}',
              child: vehicle.thumbnailUrl.isNotEmpty
                  ? (vehicle.thumbnailUrl.startsWith('assets/')
                      ? Image.asset(
                          vehicle.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          vehicle.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => VehicleIllustration(
                            brand: vehicle.brand,
                            bodyType: vehicle.bodyType,
                          ),
                        ))
                  : VehicleIllustration(
                      brand: vehicle.brand,
                      bodyType: vehicle.bodyType,
                    ),
            ),
            // Gradiente de baixo para cima
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.background, Colors.transparent],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Skeleton de carregamento
// ─────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.surface,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: AppColors.shimmerBase),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(200, 28),
                const SizedBox(height: 10),
                _shimmer(120, 16),
                const SizedBox(height: 16),
                _shimmer(double.infinity, 56),
                const SizedBox(height: 20),
                _shimmer(double.infinity, 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmer(double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
