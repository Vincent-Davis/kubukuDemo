import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controller/auth_controller.dart';
import 'presentation/authentication/login.dart';
import 'screens/main_dashboard.dart';
import 'services/product_service.dart';
import 'services/transaction_service.dart';

void main() {
  runApp(const KuBukuApp());
}

class KuBukuApp extends StatelessWidget {
  const KuBukuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final authController = AuthController();
            // Initialize services with AuthController
            ProductService.setAuthController(authController);
            TransactionService.setAuthController(authController);
            return authController;
          },
        ),
      ],
      child: MaterialApp(
        title: 'KuBuku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF5c2d91),
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5c2d91),
            primary: const Color(0xFF5c2d91),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF5c2d91),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5c2d91),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AuthenticationWrapper(),
        routes: {'/main': (context) => const MainDashboard()},
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        if (authController.isLoggedIn) {
          return const MainDashboard();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}