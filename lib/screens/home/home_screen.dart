import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../home/tabs/home_tab.dart';
import '../home/tabs/inventory_tab.dart';
import '../home/tabs/sales_tab.dart';
import '../home/tabs/reports_tab.dart';
import '../profile/profile_screen.dart';
import '../../widgets/global_header.dart';
import '../inventory/add_product_screen.dart';
import '../sales/new_sale_screen.dart';

/// Pantalla principal con navegación inferior
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static HomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<HomeScreenState>();
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showProfile = false;
  bool _showAddProduct = false;
  bool _showNewSale = false;

  void showProfile() {
    setState(() {
      _showProfile = true;
      _showAddProduct = false;
      _showNewSale = false;
    });
  }

  void hideProfile() {
    setState(() {
      _showProfile = false;
    });
  }

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
      _showProfile = false;
      _showAddProduct = false;
      _showNewSale = false;
    });
  }

  void showAddProduct() {
    setState(() {
      _showAddProduct = true;
      _showProfile = false;
      _showNewSale = false;
    });
  }

  void hideAddProduct() {
    setState(() {
      _showAddProduct = false;
    });
  }

  void showNewSale() {
    setState(() {
      _showNewSale = true;
      _showAddProduct = false;
      _showProfile = false;
    });
  }

  void hideNewSale() {
    setState(() {
      _showNewSale = false;
    });
  }

  final List<Widget> _tabs = const [
    HomeTab(),
    InventoryTab(),
    SalesTab(),
    ReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showAddProduct && !_showProfile && !_showNewSale,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        if (_showAddProduct) {
          hideAddProduct();
        } else if (_showProfile) {
          hideProfile();
        } else if (_showNewSale) {
          hideNewSale();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            if (!_showAddProduct && !_showNewSale) const GlobalHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showProfile 
                    ? const ProfileScreen() 
                    : _showAddProduct 
                        ? const AddProductScreen() 
                        : _showNewSale
                            ? const NewSaleScreen()
                            : _tabs[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Ventas',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = !_showProfile && !_showAddProduct && !_showNewSale && _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          _showProfile = false;
          _showAddProduct = false;
          _showNewSale = false;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textHint,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryGreen : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
