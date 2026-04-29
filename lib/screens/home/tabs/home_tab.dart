import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../models/product_model.dart';
import '../../../services/user_service.dart';
import '../../../services/product_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _userService = UserService();
  final _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saludo y Rol ──
          StreamBuilder<UserModel?>(
            stream: _userService.getUserProfileStream(uid, email),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const _GreetingSkeleton();
              }
              final user = snapshot.data;
              final nombre = user?.nombre.split(' ').first ?? 'Usuario';
              final rol = user?.rol ?? 'Cargando rol...';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '¡Buenos días, ',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '$nombre!',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen, // Cambiado al verde principal
                          ),
                        ),
                        const TextSpan(
                          text: ' 👋',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rol,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),

          // ── Tarjetas de Resumen ──
          StreamBuilder<List<ProductModel>>(
            stream: _productService.getProductsStream(),
            builder: (context, snapshot) {
              int criticalCount = 0;
              List<ProductModel> criticalProducts = [];
              
              if (snapshot.hasData) {
                criticalProducts = snapshot.data!
                    .where((p) => p.stock <= 10)
                    .toList();
                // Ordenar para mostrar primero los que tienen menos stock
                criticalProducts.sort((a, b) => a.stock.compareTo(b.stock));
                criticalCount = criticalProducts.length;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          title: 'VENTAS DIARIAS',
                          value: 'S/. 0.00',
                          icon: Icons.shopping_bag_outlined,
                          iconColor: AppTheme.primaryGreen,
                          iconBg: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          indicatorText: '0.0% vs ayer',
                          indicatorColor: AppTheme.textHint,
                          indicatorBg: AppTheme.backgroundGrey,
                          indicatorIcon: Icons.remove_rounded,
                          actionText: 'Ver desglose',
                          onAction: () {},
                          leftBorderColor: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DashboardCard(
                          title: 'ARTÍCULOS CRÍTICOS',
                          value: criticalCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.redAccent,
                          iconBg: Colors.red.shade50,
                          indicatorText: 'Requieren atención inmediata',
                          indicatorColor: Colors.redAccent,
                          indicatorBg: Colors.red.shade50,
                          indicatorIcon: null,
                          actionText: 'Reabastecer',
                          onAction: () {},
                          leftBorderColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // ── Alertas de Inventario ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alertas de Inventario',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Artículos por debajo del punto de reorden',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(
                              'Ver todo',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryGreen),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (criticalProducts.isEmpty)
                    _buildEmptyAlerts()
                  else
                    ...criticalProducts.take(5).map((product) => _AlertItem(product: product)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAlerts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 40, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Todo en orden!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'No hay artículos con stock crítico.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 200, height: 28, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String indicatorText;
  final Color indicatorColor;
  final Color indicatorBg;
  final IconData? indicatorIcon;
  final String actionText;
  final VoidCallback onAction;
  final Color leftBorderColor;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.indicatorText,
    required this.indicatorColor,
    required this.indicatorBg,
    this.indicatorIcon,
    required this.actionText,
    required this.onAction,
    required this.leftBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 16, color: iconColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: indicatorBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (indicatorIcon != null) ...[
                          Icon(indicatorIcon, size: 10, color: indicatorColor),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            indicatorText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: indicatorColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: onAction,
                    child: Row(
                      children: [
                        Text(
                          actionText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: leftBorderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final ProductModel product;

  const _AlertItem({required this.product});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusText;
    Color leftBorderColor;

    if (product.stock <= 0) {
      statusColor = Colors.redAccent;
      statusBg = Colors.red.withValues(alpha: 0.1);
      statusText = 'Agotado';
      leftBorderColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent.shade700;
      statusBg = Colors.orange.withValues(alpha: 0.1);
      statusText = 'Stock Bajo';
      leftBorderColor = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Imagen del producto (placeholder)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppTheme.textHint, size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  // Nombres y SKU
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${product.codigoBarras ?? product.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Stock y Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.stock}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'UNIDADES',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // Icono >
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textHint),
                ],
              ),
            ),
            // Borde lateral del alert item
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: leftBorderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
