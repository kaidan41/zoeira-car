import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/auth_controller.dart';
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
        // Avatar / login / perfil
        Consumer2<AuthController, SubscriptionController>(
          builder: (context, auth, sub, __) {
            final isLoggedIn = auth.isLoggedIn;
            final initial = (auth.displayName?.trim().isNotEmpty == true)
                ? auth.displayName!.trim()[0].toUpperCase()
                : (auth.email?.trim().isNotEmpty == true
                    ? auth.email!.trim()[0].toUpperCase()
                    : 'P');

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  if (isLoggedIn) {
                    _showProfileModal(context, auth, sub);
                  } else {
                    context.push(AppRoutes.login);
                  }
                },
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: isLoggedIn
                      ? (sub.isSubscriber
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3))
                      : AppColors.cardBorder,
                  child: isLoggedIn
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sub.isSubscriber
                                ? Colors.black
                                : AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showProfileModal(
    BuildContext context,
    AuthController auth,
    SubscriptionController sub,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final initial = (auth.displayName?.trim().isNotEmpty == true)
            ? auth.displayName!.trim()[0].toUpperCase()
            : (auth.email?.trim().isNotEmpty == true
                ? auth.email!.trim()[0].toUpperCase()
                : 'P');

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de arrasto
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar
                CircleAvatar(
                  radius: 34,
                  backgroundColor: sub.isSubscriber
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: sub.isSubscriber ? Colors.black : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nome
                Text(
                  auth.displayName ?? 'Piloto Zoeira',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  auth.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),

                // Badge de status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sub.isSubscriber
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sub.isSubscriber
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sub.isSubscriber
                            ? Icons.workspace_premium_rounded
                            : Icons.check_circle_outline_rounded,
                        color: sub.isSubscriber
                            ? AppColors.primary
                            : AppColors.verdictGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        auth.isAdmin
                            ? 'Administrador / Acesso VIP 👑'
                            : (sub.isSubscriber
                                ? 'Assinante Capivara 🦫'
                                : 'Conta Ativa na Garagem 🚗'),
                        style: TextStyle(
                          color: sub.isSubscriber
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botão Assinatura / Planos
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.subscription);
                    },
                    icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                    label: Text(
                      sub.isSubscriber
                          ? 'Gerenciar Assinatura'
                          : 'Puxar a Capivara da Nave',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botão Sair da Conta
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await auth.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Você saiu da garagem. Até a próxima! 🚗'),
                            backgroundColor: AppColors.surface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.verdictRed, size: 18),
                    label: const Text(
                      'Sair da Conta',
                      style: TextStyle(
                          color: AppColors.verdictRed,
                          fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.verdictRed),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
