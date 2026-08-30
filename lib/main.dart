import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:zoeira_car/controllers/subscription_controller.dart';
import 'package:zoeira_car/controllers/auth_controller.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ZoeiraCarApp());
}

class ZoeiraCarApp extends StatelessWidget {
  const ZoeiraCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, SubscriptionController>(
          create: (_) => SubscriptionController(),
          update: (_, auth, sub) => sub!..updateAuth(auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'Zoeira Car',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
