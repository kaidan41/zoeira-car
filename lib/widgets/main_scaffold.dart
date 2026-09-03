import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Scaffold principal com BottomNavigationBar compartilhado entre as rotas.
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context, location),
    );
  }

  Widget _buildBottomNav(BuildContext context, String location) {
    // Não exibe a bottom bar na tela de detalhe
    if (location.startsWith('/veiculo/')) {
      return const SizedBox.shrink();
    }

    final currentIndex = _indexFromLocation(location);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => _onNavTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline_rounded,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.play_circle_rounded,
                color: AppColors.primary),
            label: 'Vídeos',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.search_rounded,
                color: AppColors.primary),
            label: 'Buscar Nave',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.category_rounded,
                color: AppColors.primary),
            label: 'Categorias',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined,
                color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.workspace_premium_rounded,
                color: AppColors.primary),
            label: 'Assinatura',
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.categories)) return 2;
    if (location.startsWith(AppRoutes.subscription)) return 3;
    return 0; // home
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.search);
        break;
      case 2:
        context.go(AppRoutes.categories);
        break;
      case 3:
        context.go(AppRoutes.subscription);
        break;
    }
  }
}
