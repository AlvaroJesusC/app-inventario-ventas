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
      child: Row(
        children: [
          // Botón de menú
          GestureDetector(
            onTap: () {
              // TODO: Abrir drawer/menú lateral
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(
                Icons.menu_rounded,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Título centrado
          const Expanded(
            child: Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Avatar de perfil
          GestureDetector(
            onTap: () {
              final homeState = HomeScreen.of(context);
              if (homeState != null) {
                homeState.showProfile();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              }
            },
            child: StreamBuilder<UserModel?>(
              stream: UserService().getUserProfileStream(
                FirebaseAuth.instance.currentUser?.uid ?? '',
                FirebaseAuth.instance.currentUser?.email ?? '',
              ),
              builder: (context, snapshot) {
                final initials = snapshot.data?.initials ?? '';
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: initials.isEmpty
                        ? const Icon(Icons.person_rounded, size: 22, color: AppTheme.primaryGreen)
                        : Text(initials, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
