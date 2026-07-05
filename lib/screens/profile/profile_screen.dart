import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();

  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          title: const Text('Editar Nombre de Usuario'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Ej. Juan Doe'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _userService.updateField(
                    uid,
                    'nombre',
                    controller.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha enviado un correo para restablecer tu contraseña.',
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: StreamBuilder<UserModel?>(
        stream: _userService.getUserProfileStream(
          uid,
          FirebaseAuth.instance.currentUser?.email ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Error: No se encontró perfil'));
          }

          final bool isAdmin = user.rol.toLowerCase().contains('admin');

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // Avatar Grande y Nombres (Alineados al estilo de tu imagen, centrados en el fondo blanco)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.nombre,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.rol,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Configuración de Cuenta
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cuenta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestiona tu información personal y preferencias',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHint.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Column(
                                children: [
                                  _buildSettingsItem(
                                    icon: Icons.person_outline_rounded,
                                    iconColor: const Color(0xFF1976D2), // Azul
                                    iconBg: const Color(0xFFE3F2FD),
                                    title: 'Información Personal',
                                    subtitle: 'Nombre, usuario y datos personales',
                                    onTap: () => _showEditNameDialog(user.nombre),
                                  ),
                                  _buildSettingsItem(
                                    icon: Icons.mail_outline_rounded,
                                    iconColor: const Color(0xFF388E3C), // Verde
                                    iconBg: const Color(0xFFE8F5E9),
                                    title: 'Correo Electrónico',
                                    subtitle: 'Actualiza tu correo electrónico',
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('El correo no se puede cambiar en esta versión.'),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildSettingsItem(
                                    icon: Icons.lock_outline_rounded,
                                    iconColor: const Color(0xFF7B1FA2), // Morado
                                    iconBg: const Color(0xFFF3E5F5),
                                    title: 'Cambiar Contraseña',
                                    subtitle: 'Mantén tu cuenta segura',
                                    showDivider: true, // Siempre hay al menos otra opción abajo
                                    onTap: () => _handlePasswordReset(user.email),
                                  ),
                                  if (isAdmin)
                                    _buildSettingsItem(
                                      icon: Icons.people_outline_rounded,
                                      iconColor: const Color(0xFFF57C00), // Naranja
                                      iconBg: const Color(0xFFFFF3E0),
                                      title: 'Gestionar Usuarios',
                                      subtitle: 'Administra los usuarios del sistema',
                                      showNewBadge: true,
                                      onTap: () {
                                        HomeScreen.of(context)?.showUserManagement();
                                      },
                                    ),
                                  _buildSettingsItem(
                                    icon: Icons.settings_outlined,
                                    iconColor: const Color(0xFF616161), // Gris
                                    iconBg: const Color(0xFFF5F5F5),
                                    title: 'Configuración General',
                                    subtitle: 'Preferencias y configuraciones del sistema',
                                    showDivider: false, // Es la última opción
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Próximamente...')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Botón de Cerrar Sesión
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _handleSignOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFEBEE),
                                  foregroundColor: const Color(0xFFD32F2F),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text(
                                  'Cerrar Sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showNewBadge = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showNewBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Nuevo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppTheme.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}
