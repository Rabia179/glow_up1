import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/wishlist_repository.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final ProductRepository? productRepository;
  final WishlistRepository? wishlistRepository;
  final CartRepository? cartRepository;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.productRepository,
    this.wishlistRepository,
    this.cartRepository,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductRepository _productRepository;
  late final WishlistRepository _wishlistRepository;
  late final CartRepository _cartRepository;

  ProductModel? _product;
  bool _isLoading = true;
  bool _isWishlisted = false;
  String? _errorMessage;

  int _quantity = 1;
  int _selectedSizeMl = 30; // 30ml vs 50ml
  bool _benefitsExpanded = false;
  bool _ingredientsExpanded = false;
  bool _ritualExpanded = false;

  @override
  void initState() {
    super.initState();
    _productRepository = widget.productRepository ?? ProductRepository();
    _wishlistRepository = widget.wishlistRepository ?? WishlistRepository();
    _cartRepository = widget.cartRepository ?? CartRepository();

    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final product = await _productRepository.getProductById(widget.productId);
      final isFav = await _wishlistRepository.isWishlisted(widget.productId);

      if (mounted) {
        setState(() {
          _product = product;
          _isWishlisted = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load product details.';
          _isLoading = false;
        });
      }
    }
  }

  int get _calculatedUnitPrice {
    if (_product == null) return 0;
    if (_selectedSizeMl == 50) {
      return (_product!.price * 1.48).toInt();
    }
    return _product!.price;
  }

  int get _totalPrice {
    return _calculatedUnitPrice * _quantity;
  }

  Future<void> _toggleWishlist() async {
    final nowFav = await _wishlistRepository.toggleWishlist(widget.productId);
    if (!mounted) return;
    setState(() {
      _isWishlisted = nowFav;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowFav ? 'Added to Wishlist' : 'Removed from Wishlist',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addToCart() async {
    final messenger = ScaffoldMessenger.of(context);
    await _cartRepository.addToCart(widget.productId, quantity: _quantity);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Added ${_quantity}x ${_product?.title} ($_selectedSizeMl ml) to Shopping Bag!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Formulation not found in local database.',
                style: AppTextStyles.bodyMd(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product.title,
          style: AppTextStyles.headlineSm().copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.onSurfaceVariant),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product link copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: AppColors.primary,
            ),
            onPressed: _toggleWishlist,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Badges & Image Showcase
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Stack(
                      children: [
                        Container(
                          height: 320,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.spa_rounded,
                                size: 64,
                                color: AppColors.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        // Badge Pills Top Left & Bottom
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '100% Vegan & Biomimetic',
                                  style: AppTextStyles.labelSm(color: AppColors.secondary)
                                      .copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dewy Finish',
                                  style: AppTextStyles.labelSm(color: AppColors.tertiary)
                                      .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Editorial Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Breadcrumb
                        Row(
                          children: [
                            Text(
                              product.category.toUpperCase(),
                              style: AppTextStyles.labelSm(color: AppColors.secondary),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.outlineVariant,
                            ),
                            Text(
                              product.subtitle.toUpperCase(),
                              style: AppTextStyles.labelSm(color: AppColors.primary)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Title & Price
                        Text(
                          product.title,
                          style: AppTextStyles.headlineLg().copyWith(fontSize: 26),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Text(
                              AppConstants.formatPrice(_calculatedUnitPrice),
                              style: AppTextStyles.priceLg().copyWith(fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'Sample catalogue price',
                                style: AppTextStyles.labelSm(color: AppColors.tertiary)
                                    .copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Rating Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.9',
                                    style: AppTextStyles.labelMd(color: AppColors.onSurface)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(128 reviews)',
                                    style: AppTextStyles.bodySm(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          product.description ??
                              'An ultra-hydrating elixir infused with wild cold-pressed botanical oils to restore skin barrier health and deliver a lit-from-within finish.',
                          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                        ),

                        const SizedBox(height: 20),

                        // Size Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SELECT SIZE',
                              style: AppTextStyles.labelMd(color: AppColors.onSurface)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_selectedSizeMl ml Daily Ritual',
                              style: AppTextStyles.labelSm(color: AppColors.primary),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            // 30ml
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSizeMl = 30;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedSizeMl == 30
                                        ? AppColors.surfaceContainerLowest
                                        : AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedSizeMl == 30
                                          ? AppColors.primary
                                          : AppColors.outlineVariant.withValues(alpha: 0.4),
                                      width: _selectedSizeMl == 30 ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '30ml',
                                        style: AppTextStyles.labelLg(color: AppColors.primary)
                                            .copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Standard Glow',
                                        style: AppTextStyles.bodySm(
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppConstants.formatPrice(product.price),
                                        style: AppTextStyles.priceMd(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 50ml
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSizeMl = 50;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedSizeMl == 50
                                        ? AppColors.surfaceContainerLowest
                                        : AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedSizeMl == 50
                                          ? AppColors.primary
                                          : AppColors.outlineVariant.withValues(alpha: 0.4),
                                      width: _selectedSizeMl == 50 ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '50ml',
                                            style: AppTextStyles.labelLg(
                                              color: AppColors.onSurface,
                                            ).copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.tertiaryFixed,
                                              borderRadius: BorderRadius.circular(9999),
                                            ),
                                            child: Text(
                                              'Save 15%',
                                              style: AppTextStyles.labelSm(
                                                color: AppColors.onTertiaryFixed,
                                              ).copyWith(fontSize: 9),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Jumbo Ritual',
                                        style: AppTextStyles.bodySm(
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppConstants.formatPrice(
                                            (product.price * 1.48).toInt()),
                                        style: AppTextStyles.priceMd(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Feature Pills Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFeaturePill(Icons.water_drop_rounded, 'Cold-Pressed'),
                              const SizedBox(width: 8),
                              _buildFeaturePill(Icons.spa_rounded, 'Squalane 100%'),
                              const SizedBox(width: 8),
                              _buildFeaturePill(Icons.verified_rounded, 'Barrier Safe'),
                              const SizedBox(width: 8),
                              _buildFeaturePill(Icons.favorite_rounded, 'Non-comedogenic'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Collapsible Accordions
                        _buildAccordion(
                          title: 'Key Botanical Benefits',
                          icon: Icons.auto_awesome_rounded,
                          isExpanded: _benefitsExpanded,
                          onTap: () {
                            setState(() {
                              _benefitsExpanded = !_benefitsExpanded;
                            });
                          },
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('• Deep Hydration: Multi-weight hyaluronic complex binds water deep in the skin.'),
                              SizedBox(height: 4),
                              Text('• Tone Equalizer: Stabilized Niacinamide refines pore texture and balances skin.'),
                              SizedBox(height: 4),
                              Text('• Lustrous Glow: Plant squalane seals moisture for an all-day luminous glass finish.'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildAccordion(
                          title: 'Full Ingredients (Clean Standard)',
                          icon: Icons.science_rounded,
                          isExpanded: _ingredientsExpanded,
                          onTap: () {
                            setState(() {
                              _ingredientsExpanded = !_ingredientsExpanded;
                            });
                          },
                          content: Text(
                            'Aqua/Water/Eau, Rosa Canina (Rosehip) Seed Oil*, Niacinamide (Vitamin B3), Glycerin, Biomimetic Squalane (Olive-Derived), Sodium Hyaluronate, Panthenol (Pro-Vitamin B5), Tocopherol (Vitamin E), Camellia Sinensis Leaf Extract, Xanthan Gum.',
                            style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildAccordion(
                          title: 'Ritual & Application Instructions',
                          icon: Icons.self_improvement_rounded,
                          isExpanded: _ritualExpanded,
                          onTap: () {
                            setState(() {
                              _ritualExpanded = !_ritualExpanded;
                            });
                          },
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('1. Cleanse & Mist: Dispense onto freshly toned, slightly damp skin.'),
                              SizedBox(height: 4),
                              Text('2. Press: Release 2–3 drops into warm palms and press inward.'),
                              SizedBox(height: 4),
                              Text('3. Lock: Allow 60 seconds to absorb before applying moisturizer.'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Sticky Bottom Purchase Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14702D46),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Selector
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() {
                              _quantity--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_rounded, size: 18),
                      ),
                      Text(
                        '$_quantity',
                        style: AppTextStyles.titleMd().copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Add to Bag CTA Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Add to Bag • ${AppConstants.formatPrice(_totalPrice)}',
                              style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                                  .copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordion({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: AppTextStyles.titleMd().copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: content,
            ),
        ],
      ),
    );
  }
}
