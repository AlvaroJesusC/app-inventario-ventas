import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Widget que escucha el estado de autenticación y muestra
/// la pantalla correspondiente (Login o Home), realizando
/// el inicio de sesión automático si existen credenciales guardadas.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingAutoLogin = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // 1. Verificamos si Firebase ya tiene un usuario activo (persistencia nativa)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _isCheckingAutoLogin = false;
        });
        return;
      }

      // 2. Si no, verificamos SharedPreferences para ver si debe recordar sesión
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');

      if (rememberMe && savedEmail != null && savedPassword != null) {
        // Intentar inicio de sesión automático
        await _authService.signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
        );
      }
    } catch (e) {
      // Si falla el auto-login (p. ej. sin internet o credenciales cambiadas),
      // simplemente dejamos que el usuario vaya al login.
      debugPrint('Error en auto-login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAutoLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAutoLogin) {
      return _buildSplash();
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Mientras se determina el estado de auth, mostrar splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplash();
        }

        // Si hay usuario autenticado → Home, si no → Login
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildSplash() {
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
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 40,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
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
}
