import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/product.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../06_product_details/product_details_screen.dart';

class ProductListingScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? initialSearchQuery;
  final ProductRepository? productRepository;
  final WishlistRepository? wishlistRepository;
  final CartRepository? cartRepository;

  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.initialSearchQuery,
    this.productRepository,
    this.wishlistRepository,
    this.cartRepository,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late final ProductRepository _productRepository;
  late final WishlistRepository _wishlistRepository;
  late final CartRepository _cartRepository;

  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = [];
  Set<String> _wishlistedIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  String? _activeCategoryFilter;
  String? _activeCategoryName;
  String _sortOption = 'Default'; // Default, PriceLowToHigh, PriceHighToLow

  @override
  void initState() {
    super.initState();
    _productRepository = widget.productRepository ?? ProductRepository();
    _wishlistRepository = widget.wishlistRepository ?? WishlistRepository();
    _cartRepository = widget.cartRepository ?? CartRepository();

    _activeCategoryFilter = widget.categoryId;
    _activeCategoryName = widget.categoryName;
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadProductsAndWishlist();
  }

  Future<void> _loadProductsAndWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<ProductModel> result;
      final query = _searchController.text.trim();

      if (query.isNotEmpty) {
        result = await _productRepository.searchProducts(query);
        if (_activeCategoryFilter != null) {
          result = result
              .where((p) =>
                  p.category.toLowerCase() == _activeCategoryFilter!.toLowerCase())
              .toList();
        }
      } else if (_activeCategoryFilter != null) {
        result = await _productRepository.getProductsByCategory(_activeCategoryFilter!);
      } else {
        result = await _productRepository.getAllProducts();
      }

      // Apply Sorting
      if (_sortOption == 'PriceLowToHigh') {
        result.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortOption == 'PriceHighToLow') {
        result.sort((a, b) => b.price.compareTo(a.price));
      }

      final wishlisted = await _wishlistRepository.getWishlistItems();

      if (mounted) {
        setState(() {
          _products = result;
          _wishlistedIds = wishlisted.map((p) => p.id).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load formulations.';
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _activeCategoryFilter = null;
      _activeCategoryName = null;
      _sortOption = 'Default';
    });
    _loadProductsAndWishlist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _activeCategoryName ?? 'Products';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.network(
              AppConstants.fallbackLogoUrl,
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.spa_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              titleText,
              style: AppTextStyles.headlineSm().copyWith(fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Search Input
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A702D46),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _loadProductsAndWishlist(),
                            onChanged: (val) {
                              if (val.isEmpty) _loadProductsAndWishlist();
                            },
                            style: AppTextStyles.bodyMd(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Search formulations...',
                              hintStyle: AppTextStyles.bodyMd(color: AppColors.outline),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _loadProductsAndWishlist();
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Horizontal Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Active Category Chip
                        if (_activeCategoryName != null) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeCategoryFilter = null;
                                _activeCategoryName = null;
                              });
                              _loadProductsAndWishlist();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Active: $_activeCategoryName',
                                    style: AppTextStyles.labelMd(color: AppColors.onPrimary),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.cancel_rounded,
                                    size: 14,
                                    color: AppColors.onPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Sort Selection Popup Chip
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() {
                              _sortOption = value;
                            });
                            _loadProductsAndWishlist();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'Default',
                              child: Text('Default Order'),
                            ),
                            PopupMenuItem(
                              value: 'PriceLowToHigh',
                              child: Text('Price: Low to High'),
                            ),
                            PopupMenuItem(
                              value: 'PriceHighToLow',
                              child: Text('Price: High to Low'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swap_vert_rounded,
                                  size: 16,
                                  color: AppColors.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sortOption == 'PriceLowToHigh'
                                      ? 'Low to High'
                                      : _sortOption == 'PriceHighToLow'
                                          ? 'High to Low'
                                          : 'Sort: Default',
                                  style: AppTextStyles.labelMd(color: AppColors.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // SQLite Sync Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.storage_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'In Stock (SQLite Local)',
                                style: AppTextStyles.labelSm(
                                  color: AppColors.onSecondaryFixedVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_activeCategoryFilter != null || _searchController.text.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(
                              'Reset All',
                              style: AppTextStyles.labelMd(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Results Summary Line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_products.length} curated formulations',
                    style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live Sync',
                        style: AppTextStyles.labelSm(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Main Product Grid / States
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, style: AppTextStyles.bodyMd()),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadProductsAndWishlist,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No formulations found.',
                                    style: AppTextStyles.headlineSm(),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try adjusting your search or category filter.',
                                    style: AppTextStyles.bodyMd(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _clearFilters,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9999),
                                      ),
                                    ),
                                    child: const Text('Clear All Filters'),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.58,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                final isFav = _wishlistedIds.contains(product.id);

                                return ProductCard(
                                  title: product.title,
                                  subtitle: product.subtitle,
                                  price: product.price,
                                  badgeText: product.badgeText,
                                  imageUrl: product.imageUrl,
                                  isFavorite: isFav,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(
                                          productId: product.id,
                                        ),
                                      ),
                                    );
                                  },
                                  onFavoriteTap: () async {
                                    final nowFav =
                                        await _wishlistRepository.toggleWishlist(product.id);
                                    if (!mounted) return;
                                    setState(() {
                                      if (nowFav) {
                                        _wishlistedIds.add(product.id);
                                      } else {
                                        _wishlistedIds.remove(product.id);
                                      }
                                    });
                                  },
                                  onQuickAddTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await _cartRepository.addToCart(product.id, quantity: 1);
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added ${product.title} to Shopping Bag!',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
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
