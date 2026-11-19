import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/repositories/cart_repository.dart';
import '03_home/home_screen.dart';
import '04_categories/categories_screen.dart';
import '05_product_listing/product_listing_screen.dart';
import '07_shopping_bag/shopping_bag_screen.dart';
import '10_wishlist/wishlist_screen.dart';
import '11_profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final CartRepository? cartRepository;

  const MainNavigationScreen({super.key, this.cartRepository});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final CartRepository _cartRepository;
  int _cartCount = 0;
  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cartRepository = widget.cartRepository ?? CartRepository();
    _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    try {
      final count = await _cartRepository.getTotalItemCount();
      if (mounted) {
        setState(() {
          _cartCount = count;
        });
      }
    } catch (_) {}
  }

  void _openProductListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductListingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(isCurrentTab: _currentIndex == 0),
      const CategoriesScreen(),
      WishlistScreen(
        isCurrentTab: _currentIndex == 2,
        onExplorePressed: _openProductListing,
        onCartChanged: _refreshCartCount,
      ),
      ShoppingBagScreen(
        isCurrentTab: _currentIndex == 3,
        cartRepository: _cartRepository,
        onExplorePressed: _openProductListing,
        onCartChanged: _refreshCartCount,
      ),
      ProfileScreen(
        key: _profileKey,
        isCurrentTab: _currentIndex == 4,
        onExplorePressed: _openProductListing,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14702D46),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.grid_view_rounded,
                  label: 'Explore',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.favorite_rounded,
                  label: 'Wishlist',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.shopping_bag_rounded,
                  label: 'Bag',
                  badgeCount: _cartCount,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.onSecondaryContainer;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _refreshCartCount();
        if (index == 4) {
          (_profileKey.currentState as dynamic)?.reloadProfileAndOrders();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: AppTextStyles.labelSm(color: AppColors.onPrimary).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSm(color: color).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            // Active Dot Indicator
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
