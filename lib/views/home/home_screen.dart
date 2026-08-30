import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/home_controller.dart';
import 'package:zoeira_car/controllers/subscription_controller.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/views/home/widgets/video_player_section.dart';
import 'package:zoeira_car/views/home/widgets/video_list_section.dart';
import 'package:zoeira_car/views/home/widgets/featured_vehicles_banner.dart';
import 'package:zoeira_car/views/home/widgets/subscription_cta_banner.dart';
import 'package:zoeira_car/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    // Carrega os dados após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAll();
    });
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _controller.refresh,
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──
              _buildSliverAppBar(context),

              // ── Player do vídeo em destaque ──
              SliverToBoxAdapter(
                child: Consumer<HomeController>(
                  builder: (_, ctrl, __) => VideoPlayerSection(
                    video: ctrl.selectedVideo,
                    isLoading: ctrl.isLoadingVideos,
                  ),
                ),
              ),

              // ── Banner CTA assinatura (para não assinantes) ──
              SliverToBoxAdapter(
                child: Consumer<SubscriptionController>(
                  builder: (_, sub, __) {
                    if (sub.isSubscriber) return const SizedBox.shrink();
                    return SubscriptionCtaBanner(
                      onTap: () => context.push(AppRoutes.search),
                    );
                  },
                ),
              ),

              // ── Veículos em destaque ──
              SliverToBoxAdapter(
                child: Consumer<HomeController>(
                  builder: (_, ctrl, __) {
                    if (ctrl.featuredVehicles.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return FeaturedVehiclesBanner(
                      vehicles: ctrl.featuredVehicles,
                      onVehicleTap: (id) =>
                          context.push('/veiculo/$id'),
                    );
                  },
                ),
              ),

              // ── Título da lista ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Últimos vídeos 🔥',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),

              // ── Lista de vídeos ──
              Consumer<HomeController>(
                builder: (_, ctrl, __) => VideoListSection(
                  videos: ctrl.videos,
                  isLoading: ctrl.isLoadingVideos,
                  hasError: ctrl.hasVideosError,
                  errorMessage: ctrl.videosError,
                  selectedVideoId: ctrl.selectedVideo?.videoId,
                  onVideoTap: _controller.selectVideo,
                  onRetry: _controller.loadVideos,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // Logo / título
          Text(
            'ZOEIRA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
          ),
          Text(
            ' CAR',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
          ),
        ],
      ),
      actions: [
        // Botão de busca
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
          onPressed: () => context.push(AppRoutes.search),
          tooltip: 'Procurar Nave',
        ),
        // Avatar / login
        Consumer<SubscriptionController>(
          builder: (_, sub, __) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push(
                sub.isSubscriber ? AppRoutes.subscription : AppRoutes.login,
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    sub.isSubscriber ? AppColors.primary : AppColors.cardBorder,
                child: Icon(
                  sub.isSubscriber
                      ? Icons.workspace_premium_rounded
                      : Icons.person_rounded,
                  size: 18,
                  color: sub.isSubscriber
                      ? Colors.black
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
