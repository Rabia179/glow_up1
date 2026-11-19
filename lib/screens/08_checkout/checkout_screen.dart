import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../09_order_confirmation/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CartRepository? cartRepository;
  final OrderRepository? orderRepository;
  final VoidCallback? onOrderCompleted;

  const CheckoutScreen({
    super.key,
    this.cartRepository,
    this.orderRepository,
    this.onOrderCompleted,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CartRepository _cartRepository;
  late final OrderRepository _orderRepository;

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedPayment = 'COD'; // 'COD' or 'DEMO_CARD'
  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _subtotal = 0;
  static const int _freeShippingThreshold = 5000;
  static const int _standardShippingFee = 250;

  @override
  void initState() {
    super.initState();
    _cartRepository = widget.cartRepository ?? CartRepository();
    _orderRepository = widget.orderRepository ?? OrderRepository();
    _loadCart();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    try {
      final items = await _cartRepository.getCartItems();
      final subtotal = await _cartRepository.getSubtotal();

      if (mounted) {
        setState(() {
          _cartItems = items;
          _subtotal = subtotal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load bag items for checkout.';
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

  int get _grandTotal => _subtotal + _shippingFee;

  Future<void> _placeOrder() async {
    if (_isSubmitting) return; // Prevent duplicate submissions

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your bag is empty. Add products before checking out.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required shipping details correctly.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fullShippingAddress =
          '${_fullNameController.text.trim()}, ${_phoneController.text.trim()}\n${_addressController.text.trim()}, ${_cityController.text.trim()} ${_postalCodeController.text.trim()}';

      final paymentMethodLabel = _selectedPayment == 'COD'
          ? 'Cash on Delivery (COD)'
          : 'Demo Card Payment (Simulation)';

      final order = await _orderRepository.createOrder(
        shippingAddress: fullShippingAddress,
        paymentMethod: paymentMethodLabel,
        items: _cartItems,
        shippingFee: _shippingFee,
      );

      widget.onOrderCompleted?.call();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(order: order),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: ${e.toString()}')),
        );
      }
    }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Text(_errorMessage!, style: AppTextStyles.bodyMd()),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Shipping Address Section
                    _buildSectionHeader('1. SHIPPING ADDRESS', Icons.location_on_outlined),

                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      hint: 'e.g. Ayesha Khan',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number (PK) *',
                      hint: 'e.g. 03001234567',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Enter a valid Pakistani phone number (min 10 digits)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Street Address *',
                      hint: 'e.g. House 12, Block 4, Gulberg III',
                      icon: Icons.home_outlined,
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Enter complete street address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City *',
                            hint: 'Lahore, Karachi, etc.',
                            icon: Icons.location_city_outlined,
                            validator: (value) {
                              if (value == null || value.trim().length < 2) {
                                return 'Enter city';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _postalCodeController,
                            label: 'Postal Code *',
                            hint: 'e.g. 54000',
                            icon: Icons.markunread_mailbox_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().length < 3) {
                                return 'Enter postal code';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 2. Payment Method Section
                    _buildSectionHeader('2. PAYMENT METHOD', Icons.payment_outlined),

                    const SizedBox(height: 12),

                    _buildPaymentOption(
                      id: 'COD',
                      title: 'Cash on Delivery (COD)',
                      subtitle: 'Pay with cash upon delivery to your doorstep.',
                      icon: Icons.money_rounded,
                    ),

                    const SizedBox(height: 10),

                    _buildPaymentOption(
                      id: 'DEMO_CARD',
                      title: 'Demo Card Payment (Simulation)',
                      subtitle: 'Simulate credit/debit card transaction for demo.',
                      icon: Icons.credit_card_rounded,
                      isDemo: true,
                    ),

                    const SizedBox(height: 24),

                    // 3. Items Summary Preview
                    _buildSectionHeader('3. FORMULATIONS REVIEW', Icons.shopping_bag_outlined),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          ..._cartItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.product?.title ?? "Item"}',
                                      style: AppTextStyles.bodyMd(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    AppConstants.formatPrice(item.itemSubtotal),
                                    style: AppTextStyles.titleMd().copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: AppColors.outlineVariant),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                              Text(AppConstants.formatPrice(_subtotal), style: AppTextStyles.titleMd().copyWith(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Express Shipping', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                              Text(
                                _shippingFee == 0 ? 'FREE' : AppConstants.formatPrice(_shippingFee),
                                style: AppTextStyles.titleMd().copyWith(
                                  fontSize: 14,
                                  color: _shippingFee == 0 ? AppColors.primary : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grand Total', style: AppTextStyles.titleLg().copyWith(fontSize: 16)),
                              Text(AppConstants.formatPrice(_grandTotal), style: AppTextStyles.priceLg().copyWith(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PLACE ORDER • ${AppConstants.formatPrice(_grandTotal)}',
                        style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                            .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.labelMd(color: AppColors.onSurface)
              .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMd(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isDemo = false,
  }) {
    final isSelected = _selectedPayment == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPayment = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              size: 22,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMd().copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (isDemo) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Demo',
                            style: AppTextStyles.labelSm(color: AppColors.tertiary).copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
