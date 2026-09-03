import 'package:go_router/go_router.dart';
import 'package:zoeira_car/views/home/home_screen.dart';
import 'package:zoeira_car/views/search/search_screen.dart';
import 'package:zoeira_car/views/vehicle_detail/vehicle_detail_screen.dart';
import 'package:zoeira_car/views/subscription/subscription_screen.dart';
import 'package:zoeira_car/views/categories/categories_screen.dart';
import 'package:zoeira_car/views/auth/login_screen.dart';
import 'package:zoeira_car/views/auth/register_screen.dart';
import 'package:zoeira_car/widgets/main_scaffold.dart';

class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String vehicleDetail = '/veiculo/:id';
  static const String subscription = '/assinatura';
  static const String categories = '/categorias';
  static const String categoryVehicles = '/categorias/:id';
  static const String login = '/login';
  static const String register = '/cadastro';

  static final router = GoRouter(
    initialLocation: home,
    redirect: (context, state) {
      // Sem redirect forçado de login — app tem acesso gratuito parcial
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: vehicleDetail,
            builder: (context, state) {
              final vehicleId = state.pathParameters['id']!;
              return VehicleDetailScreen(vehicleId: vehicleId);
            },
          ),
          GoRoute(
            path: subscription,
            builder: (context, state) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: categories,
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: categoryVehicles,
            builder: (context, state) {
              final catId = state.pathParameters['id']!;
              return CategoryVehiclesScreen(categoryId: catId);
            },
          ),
        ],
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}
