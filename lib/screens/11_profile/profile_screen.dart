import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../09_order_confirmation/order_confirmation_screen.dart';
import '../12_backup_restore/backup_restore_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileRepository? profileRepository;
  final OrderRepository? orderRepository;
  final VoidCallback? onExplorePressed;
  final bool isCurrentTab;

  const ProfileScreen({
    super.key,
    this.profileRepository,
    this.orderRepository,
    this.onExplorePressed,
    this.isCurrentTab = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _profileRepository;
  late final OrderRepository _orderRepository;

  UserProfileModel? _profile;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? ProfileRepository();
    _orderRepository = widget.orderRepository ?? OrderRepository();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _loadData();
    }
  }

  void reloadProfileAndOrders() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await _profileRepository.getProfile();
      final orders = await _orderRepository.getAllOrders();

      if (mounted) {
        setState(() {
          _profile = profile;
          _orders = orders;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile data.';
          _isLoading = false;
        });
      }
    }
  }

  void _openEditProfileSheet() {
    if (_profile == null) return;

    final nameController = TextEditingController(text: _profile!.name);
    final emailController = TextEditingController(text: _profile!.email);
    final phoneController = TextEditingController(text: _profile!.phone);
    final skinTypeController = TextEditingController(text: _profile!.skinType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Local Profile',
                style: AppTextStyles.headlineSm(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: skinTypeController,
                decoration: const InputDecoration(labelText: 'Skin Type / Ritual Focus'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                  ),
                  onPressed: () async {
                    final updated = UserProfileModel(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      skinType: skinTypeController.text.trim(),
                    );
                    await _profileRepository.saveProfile(updated);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await _loadData();
                  },
                  child: const Text('SAVE CHANGES'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(order: order),
      ),
    );
  }

  void _navigateToBackupRestore() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupRestoreScreen(
          onDataRestored: () {
            _loadData();
          },
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'My Profile & Orders',
          style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _openEditProfileSheet,
            tooltip: 'Edit Profile',
          ),
          const SizedBox(width: 8),
        ],
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
                _loadData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = _profile!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F702D46),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.secondaryContainer,
                  backgroundImage: const NetworkImage(AppConstants.fallbackAvatarUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: AppTextStyles.headlineSm().copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          profile.skinType,
                          style: AppTextStyles.labelSm(color: AppColors.primary)
                              .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Google Drive Backup Tile Button
          InkWell(
            onTap: _navigateToBackupRestore,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F702D46),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive Backup & Restore',
                          style: AppTextStyles.titleMd().copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sync SQLite database to GLOW_UP_Backups folder',
                          style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Order History Section
          Text(
            'ORDER HISTORY',
            style: AppTextStyles.labelMd(color: AppColors.onSurface)
                .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),

          const SizedBox(height: 12),

          if (_orders.isEmpty)
            _buildEmptyOrdersCard()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderCard(order);
              },
            ),

          const SizedBox(height: 24),

          // 4. App & Storage Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On-Device Local Database Engine',
                        style: AppTextStyles.titleMd().copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'SQLite storage • Version 1.0.0',
                        style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text('No Orders Yet', style: AppTextStyles.titleLg()),
          const SizedBox(height: 4),
          Text(
            'Once you complete an order, your order receipts and delivery status will appear here.',
            style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (widget.onExplorePressed != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: widget.onExplorePressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: const Text('START SHOPPING'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormatted = order.orderDate.contains('T')
        ? order.orderDate.split('T').first
        : order.orderDate;

    return InkWell(
      onTap: () => _openOrderDetails(order),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: AppTextStyles.titleMd().copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixed,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    order.status,
                    style: AppTextStyles.labelSm(color: AppColors.onTertiaryFixed)
                        .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Date: $dateFormatted • ${order.paymentMethod}',
              style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.outlineVariant),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} ${order.items.length == 1 ? "item" : "items"}',
                  style: AppTextStyles.bodySm(),
                ),
                Row(
                  children: [
                    Text(
                      AppConstants.formatPrice(order.totalAmount),
                      style: AppTextStyles.priceMd().copyWith(fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.secondary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
