import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/cart_repository.dart';
import '../08_checkout/checkout_screen.dart';

class ShoppingBagScreen extends StatefulWidget {
  final CartRepository? cartRepository;
  final VoidCallback? onExplorePressed;
  final VoidCallback? onCartChanged;
  final bool isCurrentTab;

  const ShoppingBagScreen({
    super.key,
    this.cartRepository,
    this.onExplorePressed,
    this.onCartChanged,
    this.isCurrentTab = false,
  });

  @override
  State<ShoppingBagScreen> createState() => _ShoppingBagScreenState();
}

class _ShoppingBagScreenState extends State<ShoppingBagScreen> {
  late final CartRepository _cartRepository;

  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _subtotal = 0;
  int _totalItemCount = 0;

  static const int _freeShippingThreshold = 5000;
  static const int _standardShippingFee = 250;

  @override
  void initState() {
    super.initState();
    _cartRepository = widget.cartRepository ?? CartRepository();
    _loadCartData();
  }

  @override
  void didUpdateWidget(covariant ShoppingBagScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _loadCartData();
    }
  }

  Future<void> _loadCartData() async {
    try {
      final items = await _cartRepository.getCartItems();
      final subtotal = await _cartRepository.getSubtotal();
      final totalCount = await _cartRepository.getTotalItemCount();

      if (mounted) {
        setState(() {
          _cartItems = items;
          _subtotal = subtotal;
          _totalItemCount = totalCount;
          _isLoading = false;
          _errorMessage = null;
        });
        widget.onCartChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load shopping bag items.';
          _isLoading = false;
        });
      }
    }
  }

  int get _shippingFee {
    if (_subtotal == 0 || _subtotal >= _freeShippingThreshold) {
      return 0;
    }
    return _standardShippingFee;
  }

  int get _grandTotal {
    if (_subtotal == 0) return 0;
    return _subtotal + _shippingFee;
  }

  Future<void> _updateQuantity(CartItemModel item, int newQty) async {
    if (item.id == null) return;

    if (newQty <= 0) {
      await _confirmRemoveItem(item);
      return;
    }

    await _cartRepository.updateQuantity(item.id!, newQty);
    await _loadCartData();
  }

  Future<void> _confirmRemoveItem(CartItemModel item) async {
    final title = item.product?.title ?? 'Product';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Remove Item?', style: AppTextStyles.headlineSm()),
        content: Text(
          'Are you sure you want to remove "$title" from your shopping bag?',
          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.labelLg(color: AppColors.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await _cartRepository.removeFromCart(item.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "$title" from bag.')),
      );
      await _loadCartData();
    }
  }

  Future<void> _confirmClearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Clear Shopping Bag?', style: AppTextStyles.headlineSm()),
        content: Text(
          'Are you sure you want to remove all items from your bag? This action cannot be undone.',
          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.labelLg(color: AppColors.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cartRepository.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shopping bag cleared.')),
      );
      await _loadCartData();
    }
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartRepository: _cartRepository,
          onOrderCompleted: () {
            _loadCartData();
            widget.onCartChanged?.call();
          },
        ),
      ),
    );
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
              'Shopping Bag',
              style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
            ),
            if (_totalItemCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '$_totalItemCount ${_totalItemCount == 1 ? "unit" : "units"}',
                  style: AppTextStyles.labelSm(color: AppColors.primary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.primary),
              tooltip: 'Clear Bag',
              onPressed: _confirmClearCart,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _cartItems.isNotEmpty ? _buildStickyBottomBar() : null,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  _loadCartData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cartItems.isEmpty) {
      return _buildEmptyCartState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Free Shipping Progress Banner
          _buildShippingProgressBanner(),

          const SizedBox(height: 20),

          // 2. Line Items List
          Text(
            'YOUR FORMULATIONS',
            style: AppTextStyles.labelMd(color: AppColors.onSurface)
                .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),

          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItemCard(item);
            },
          ),

          const SizedBox(height: 24),

          // 3. Order Summary Breakdown Card
          _buildOrderSummaryCard(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
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
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Bag is Empty',
              style: AppTextStyles.headlineMd(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Explore our clean biomimetic serums, wild cold-pressed botanical oils, and luxury ritual sets to add items.',
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

  Widget _buildShippingProgressBanner() {
    final isUnlocked = _subtotal >= _freeShippingThreshold;
    final remaining = _freeShippingThreshold - _subtotal;
    final progress = (_subtotal / _freeShippingThreshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUnlocked ? Icons.verified_rounded : Icons.local_shipping_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUnlocked
                      ? "You've unlocked Complimentary Express Delivery!"
                      : "Add ${AppConstants.formatPrice(remaining)} more for Free Express Shipping",
                  style: AppTextStyles.titleMd().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    final product = item.product;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              product?.imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.spa_rounded, color: AppColors.outlineVariant, size: 28),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product?.category.toUpperCase() ?? 'RITUAL',
                            style: AppTextStyles.labelSm(color: AppColors.secondary)
                                .copyWith(fontSize: 10),
                          ),
                          Text(
                            product?.title ?? 'Formulation',
                            style: AppTextStyles.titleMd().copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmRemoveItem(item),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  AppConstants.formatPrice(product?.price ?? 0),
                  style: AppTextStyles.priceMd().copyWith(fontSize: 13),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Control Unit
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.remove_rounded, size: 16),
                            onPressed: () => _updateQuantity(item, item.quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: AppTextStyles.titleMd().copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            onPressed: () => _updateQuantity(item, item.quantity + 1),
                          ),
                        ],
                      ),
                    ),

                    // Line Subtotal
                    Text(
                      AppConstants.formatPrice(item.itemSubtotal),
                      style: AppTextStyles.priceMd().copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: AppTextStyles.labelMd(color: AppColors.onSurface)
                .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bag Subtotal', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
              Text(AppConstants.formatPrice(_subtotal), style: AppTextStyles.titleMd()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Express Shipping', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
              Text(
                _shippingFee == 0 ? 'FREE' : AppConstants.formatPrice(_shippingFee),
                style: AppTextStyles.titleMd().copyWith(
                  color: _shippingFee == 0 ? AppColors.primary : AppColors.onSurface,
                  fontWeight: _shippingFee == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.outlineVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (Incl. Taxes)',
                style: AppTextStyles.titleLg().copyWith(fontSize: 16),
              ),
              Text(
                AppConstants.formatPrice(_grandTotal),
                style: AppTextStyles.priceLg().copyWith(fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL',
                style: AppTextStyles.labelSm(color: AppColors.secondary),
              ),
              Text(
                AppConstants.formatPrice(_grandTotal),
                style: AppTextStyles.priceLg().copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'PROCEED TO CHECKOUT',
                          style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                              .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
