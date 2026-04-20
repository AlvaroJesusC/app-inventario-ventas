import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_theme.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Widget que escucha el estado de autenticación y muestra
/// la pantalla correspondiente (Login o Home)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se determina el estado de auth, mostrar splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 40,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Si hay usuario autenticado → Home, si no → Login
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
