import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../presentation/authentication/login.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const AuthGuard({super.key, required this.child, this.requireAuth = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // If authentication is not required, always show the child
        if (!requireAuth) {
          return child;
        }

        // Check if user is logged in
        if (authController.isLoggedIn && authController.currentUser != null) {
          return child;
        } else {
          // User is not logged in, redirect to login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          });

          // Show loading while redirecting
          return const Scaffold(
            backgroundColor: Color(0xff1b1f3b),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xff3abeff)),
            ),
          );
        }
      },
    );
  }
}
