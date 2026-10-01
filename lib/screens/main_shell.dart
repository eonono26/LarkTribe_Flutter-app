import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';

/// Current bottom-nav tab. Any screen can jump tabs: `shellTab.value = 3`.
/// 0 Discover · 1 Catalog · 2 Lookbook · 3 Bag · 4 Profile
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _tabs = [
    HomeScreen(),
    CatalogScreen(),
    WishlistScreen(),
    CartScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(index: index, children: _tabs),
        bottomNavigationBar: _AtelierNav(index: index),
      ),
    );
  }
}

class _AtelierNav extends StatelessWidget {
  final int index;
  const _AtelierNav({required this.index});

  @override
  Widget build(BuildContext context) {
    final bagCount = context.watch<CartProvider>().itemCount;
    Widget item(int i, IconData icon, IconData active, String label, {int badge = 0}) {
      final selected = index == i;
      final color = selected ? AppColors.ink : AppColors.subtext;
      return Expanded(
        child: InkWell(
          onTap: () => shellTab.value = i,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.ink,
                  textColor: Colors.white,
                  child: Icon(selected ? active : icon, size: 24, color: color),
                ),
                const SizedBox(height: 4),
                Text(label.toUpperCase(),
                    style: AppType.labelBadge(color).copyWith(
                        fontSize: 9.5,
                        letterSpacing: 1.1,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        border: const Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            item(0, Icons.explore_outlined, Icons.explore, 'Discover'),
            item(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Catalog'),
            item(2, Icons.favorite_border, Icons.favorite, 'Lookbook'),
            item(3, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Bag', badge: bagCount),
            item(4, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }
}
