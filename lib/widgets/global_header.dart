import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_constants.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';

class GlobalHeader extends StatelessWidget {
  const GlobalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(
            alpha: 0.05,
          ), // Fondo verde a baja opacidad
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icono y nombre de la App a la izquierda
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/iconoAppInv.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppConstants
                      .appName, // Usará 'StockApp' o 'MyPeru' según tu app_constants.dart
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen, // Texto verde oscuro
                  ),
                ),
              ],
            ),

            // Avatar de perfil a la derecha
            GestureDetector(
              onTap: () {
                final homeState = HomeScreen.of(context);
                if (homeState != null) {
                  homeState.showProfile();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                }
              },
              child: StreamBuilder<UserModel?>(
                stream: UserService().getUserProfileStream(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                  FirebaseAuth.instance.currentUser?.email ?? '',
                ),
                builder: (context, snapshot) {
                  // Usamos la primera letra del nombre o email como avatar fallback
                  String initials = 'U';
                  if (snapshot.hasData && snapshot.data!.initials.isNotEmpty) {
                    initials = snapshot.data!.initials;
                  }

                  return Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen, // Fondo verde oscuro
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white, // Texto blanco
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      // Punto verde de estado "Online"
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50), // Verde brillante
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFEAF4ED,
                            ), // Color sólido que simula el primaryGreen con 0.1 de alpha
                            width: 2.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}