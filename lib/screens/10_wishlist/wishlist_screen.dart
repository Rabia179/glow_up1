import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../06_product_details/product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  final WishlistRepository? wishlistRepository;
  final CartRepository? cartRepository;
  final VoidCallback? onExplorePressed;
  final VoidCallback? onCartChanged;
  final bool isCurrentTab;

  const WishlistScreen({
    super.key,
    this.wishlistRepository,
    this.cartRepository,
    this.onExplorePressed,
    this.onCartChanged,
    this.isCurrentTab = false,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final WishlistRepository _wishlistRepository;
  late final CartRepository _cartRepository;

  List<ProductModel> _wishlistProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _wishlistRepository = widget.wishlistRepository ?? WishlistRepository();
    _cartRepository = widget.cartRepository ?? CartRepository();
    _loadWishlist();
  }

  @override
  void didUpdateWidget(covariant WishlistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _loadWishlist();
    }
  }

  Future<void> _loadWishlist() async {
    try {
      final items = await _wishlistRepository.getWishlistItems();
      if (mounted) {
        setState(() {
          _wishlistProducts = items;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load wishlist items.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromWishlist(ProductModel product) async {
    await _wishlistRepository.removeFromWishlist(product.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${product.title}" from wishlist.'),
        duration: const Duration(seconds: 2),
      ),
    );

    await _loadWishlist();
  }

  Future<void> _addToBag(ProductModel product) async {
    await _cartRepository.addToCart(product.id, quantity: 1);
    widget.onCartChanged?.call();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${product.title}" to bag!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToProductDetails(String productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(productId: productId),
      ),
    );
    _loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Wishlist & Saved',
              style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
            ),
            if (_wishlistProducts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${_wishlistProducts.length}',
                  style: AppTextStyles.labelSm(color: AppColors.primary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: AppTextStyles.bodyMd()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadWishlist();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_wishlistProducts.isEmpty) {
      return _buildEmptyWishlistState();
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _wishlistProducts.length,
      itemBuilder: (context, index) {
        final product = _wishlistProducts[index];
        return _buildWishlistCard(product);
      },
    );
  }

  Widget _buildEmptyWishlistState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Wishlist is Empty',
              style: AppTextStyles.headlineMd(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Save your favorite clean serums, tinted lip oils, and glowing enhancements to keep track of your skincare wishlist.',
              style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onExplorePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text(
                  'EXPLORE COLLECTIONS',
                  style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                      .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(ProductModel product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetails(product.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F702D46),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Container(
                    color: AppColors.surfaceContainerLow,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.spa_rounded, color: AppColors.outlineVariant, size: 36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(product),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      style: AppTextStyles.labelSm(color: AppColors.secondary).copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      style: AppTextStyles.titleMd().copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppConstants.formatPrice(product.price),
                      style: AppTextStyles.priceMd().copyWith(fontSize: 14),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () => _addToBag(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                        label: Text(
                          'Add to Bag',
                          style: AppTextStyles.labelSm(color: AppColors.onPrimary).copyWith(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
