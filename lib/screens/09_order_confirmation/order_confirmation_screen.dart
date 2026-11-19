import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            'Order Receipt',
            style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // 1. Success Hero Animation Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Order Confirmed!',
                style: AppTextStyles.headlineLg().copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                'Thank you for your purchase. Your daily skincare ritual is being freshly formulated and prepared.',
                style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Order Reference Number Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'REF: ${order.id}',
                      style: AppTextStyles.labelLg(color: AppColors.primary)
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Order Metadata & Shipping Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DELIVERY DETAILS',
                      style: AppTextStyles.labelMd(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),

                    const SizedBox(height: 12),

                    _buildInfoRow(Icons.event_outlined, 'Status', order.status),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.payment_outlined, 'Payment', order.paymentMethod),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Address',
                      order.shippingAddress,
                      isMultiline: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Purchased Items List
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FORMULATIONS ORDERED',
                      style: AppTextStyles.labelMd(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),

                    const SizedBox(height: 12),

                    ...order.items.map((item) {
                      final itemSubtotal = item.price * item.quantity;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName}',
                                style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              AppConstants.formatPrice(itemSubtotal),
                              style: AppTextStyles.titleMd().copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.outlineVariant),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount Paid', style: AppTextStyles.titleLg().copyWith(fontSize: 15)),
                        Text(
                          AppConstants.formatPrice(order.totalAmount),
                          style: AppTextStyles.priceLg().copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
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
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
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
                  const Icon(Icons.home_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'RETURN TO HOME',
                    style: AppTextStyles.labelLg(color: AppColors.onPrimary)
                        .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
