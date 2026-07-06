import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/purchase_model.dart';
import '../home/tabs/home_tab.dart';
import '../home/tabs/inventory_tab.dart';
import '../home/tabs/sales_tab.dart';
import '../home/tabs/reports_tab.dart';
import '../profile/profile_screen.dart';
import '../../widgets/global_header.dart';
import '../inventory/add_product_screen.dart';
import '../inventory/new_purchase_screen.dart';
import '../sales/new_sale_screen.dart';
import '../profile/user_management_screen.dart';

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
  bool _showUserManagement = false;
  bool _showNewPurchase = false;
  PurchaseModel? _purchaseToEdit;

  final _inventoryTabKey = GlobalKey<InventoryTabState>();
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeTab(),
      const SalesTab(),
      InventoryTab(key: _inventoryTabKey),
      const ReportsTab(),
    ];
  }

  void showProfile() {
    setState(() {
      _showProfile = true;
      _showAddProduct = false;
      _showNewSale = false;
      _showUserManagement = false;
      _showNewPurchase = false;
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
      _showUserManagement = false;
      _showNewPurchase = false;
    });
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inventoryTabKey.currentState?.applyStockFilter(StockFilter.all);
      });
    }
  }

  void showCriticalInventory() {
    setState(() {
      _currentIndex = 2; // Inventory tab
      _showProfile = false;
      _showAddProduct = false;
      _showNewSale = false;
      _showUserManagement = false;
      _showNewPurchase = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inventoryTabKey.currentState?.applyStockFilter(StockFilter.critical);
    });
  }

  void showAddProduct() {
    setState(() {
      _showAddProduct = true;
      _showProfile = false;
      _showNewSale = false;
      _showUserManagement = false;
      _showNewPurchase = false;
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
      _showUserManagement = false;
      _showNewPurchase = false;
    });
  }

  void hideNewSale() {
    setState(() {
      _showNewSale = false;
    });
  }

  void showUserManagement() {
    setState(() {
      _showUserManagement = true;
      _showProfile = false;
      _showAddProduct = false;
      _showNewSale = false;
      _showNewPurchase = false;
    });
  }

  void hideUserManagement() {
    setState(() {
      _showUserManagement = false;
      _showProfile = true; // Return to profile since we came from there
    });
  }

  void showNewPurchase({PurchaseModel? purchaseToEdit}) {
    setState(() {
      _showNewPurchase = true;
      _purchaseToEdit = purchaseToEdit;
      _showAddProduct = false;
      _showProfile = false;
      _showNewSale = false;
      _showUserManagement = false;
    });
  }

  void hideNewPurchase() {
    setState(() {
      _showNewPurchase = false;
      _purchaseToEdit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showAddProduct && !_showProfile && !_showNewSale && !_showUserManagement && !_showNewPurchase,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (_showAddProduct) {
          hideAddProduct();
        } else if (_showUserManagement) {
          hideUserManagement();
        } else if (_showProfile) {
          hideProfile();
        } else if (_showNewSale) {
          hideNewSale();
        } else if (_showNewPurchase) {
          hideNewPurchase();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            if (!_showAddProduct && !_showNewSale && !_showNewPurchase) const GlobalHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      // ignore: use_null_aware_elements
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: _showUserManagement
                    ? const UserManagementScreen()
                    : _showProfile 
                        ? const ProfileScreen() 
                        : _showAddProduct 
                            ? const AddProductScreen() 
                            : _showNewSale
                                ? const NewSaleScreen()
                                : _showNewPurchase
                                    ? NewPurchaseScreen(purchaseToEdit: _purchaseToEdit)
                                    : _tabs[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (_showAddProduct || _showNewSale || _showNewPurchase) ? null : _buildBottomNavBar(),
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
                  icon: Icons.point_of_sale_rounded,
                  label: 'Ventas',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.more_horiz_rounded,
                  label: 'Más',
                  index: 4,
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
    final bool isActive = index == 4
        ? (_showProfile || _showUserManagement)
        : (!_showProfile && !_showAddProduct && !_showNewSale && !_showUserManagement && _currentIndex == index);

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          showProfile();
        } else {
          setState(() {
            _currentIndex = index;
            _showProfile = false;
            _showAddProduct = false;
            _showNewSale = false;
            _showUserManagement = false;
          });
          if (index == 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _inventoryTabKey.currentState?.applyStockFilter(StockFilter.all);
            });
          }
        }
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
