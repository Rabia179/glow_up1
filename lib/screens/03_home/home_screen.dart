import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../05_product_listing/product_listing_screen.dart';
import '../06_product_details/product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isCurrentTab;

  const HomeScreen({super.key, this.isCurrentTab = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final WishlistRepository _wishlistRepository = WishlistRepository();
  final CartRepository _cartRepository = CartRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  bool _isLoading = true;
  String _userName = 'Maya';
  Set<String> _wishlistedIds = {};
  List<CategoryModel> _categories = [];
  List<ProductModel> _featuredProducts = [];
  ProductModel? _newArrivalProduct;
  final Set<int> _completedRitualSteps = {0};

  @override
  void initState() {
    super.initState();
    _loadDataFromSQLite();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _loadDataFromSQLite();
    }
  }

  Future<void> _loadDataFromSQLite() async {
    try {
      final categories = await _categoryRepository.getAllCategories();
      final featured = await _productRepository.getFeaturedProducts();
      final wishlistItems = await _wishlistRepository.getWishlistItems();
      final newArrivals = await _productRepository.getNewArrivals();
      final profile = await _profileRepository.getProfile();

      if (mounted) {
        setState(() {
          _categories = categories;
          _featuredProducts = featured.isNotEmpty ? featured : _getFallbackFeatured();
          _wishlistedIds = wishlistItems.map((p) => p.id).toSet();
          if (newArrivals.isNotEmpty) {
            _newArrivalProduct = newArrivals.first;
          }
          _userName = profile.name.trim().isNotEmpty
              ? profile.name.trim().split(' ').first
              : 'Maya';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ProductModel> _getFallbackFeatured() {
    return const [
      ProductModel(
        id: 'product_1',
        title: 'Luminous Dew Drops',
        subtitle: '30ml Elixir Concentrate',
        price: 4850,
        badgeText: 'Bestseller',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB9hLeiB646H984oa6wUCKjdTXABqKz3ptwWIvDcRNT0MH3hpBLsR1IaYA4k6Jc64rmryKBjRmVws-zVjCQRCnx7U-9krZ7ZDbA-M2yLtfpvpw2tkmCcrzrP2k2XRvrgIpVK9EAEiqXmyPYXzPUiggdpbqeBk44C2p2ToTFPEkfp9ut1CK9Hpgwgw938UK0rVVSfwS9ri39G524avGz-zpjqHphbXlNRnHmmHlaSd-sgpU79x1sl0kC2A',
        category: 'skincare',
      ),
      ProductModel(
        id: 'product_2',
        title: 'Velvet Petal Lip Oil',
        subtitle: 'Tinted Nourishment',
        price: 2400,
        badgeText: '★ 4.9 (120)',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDIFsRz9U9wMbrvbJoVfzZVoJYUXq0e4DibWvcCyT-TqRVEW9v_Vp85eIOjl1JIBcsnQeQH5z1pppEa2TpOVZ4pJjeQdl3d2quLfhF6xVey45q42Ic2WBT2dsYembwjUCWsMa8j0uuWRrQwgNFcADaB_tcCttnCsAXX7ZFogAbiUBbIF2bKQLlsa5lWQ86l7oYJOLlzIFnI-v9PN59R_AjMUEGTcRYnbS9cdYZfLsJS797Y69phNqE0pg',
        category: 'makeup',
      ),
      ProductModel(
        id: 'product_3',
        title: 'Ceramide Barrier Cream',
        subtitle: '50ml Deep Moisture',
        price: 5200,
        badgeText: 'Hydration',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDaPXv9MTdf2alsCV9ABsTqhNd4JryxYmDEOKKF1g7iXdH_zMOMqJpnl5xTA4guF63tnW6dGOSwaZSaMGNmO0kqFjVVksLrGGyrGkZ8YpV3tv1kUahSBTUSPPom66J_givm6lxNC7KB8YlRknXqtMf2UaFf-Nel_b3Dq8e5_1D9zcC1x58wh4mpPIaWIZ2fmKjK5I2XXVDxN49SGohsiYrZGS9XDZs1nWRsj4ELjKvrLH-J38OPy1zQBQ',
        category: 'skincare',
      ),
    ];
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'spa':
        return Icons.spa_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'cyclone':
        return Icons.cyclone_rounded;
      case 'local_florist':
        return Icons.local_florist_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar
              _buildHeader(context),

              if (_isLoading)
                const LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceContainerLow,
                  minHeight: 2,
                ),

              const SizedBox(height: 12),

              // 2. Greeting & Offline Sync Badge
              _buildGreetingSection(),

              const SizedBox(height: 16),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomSearchField(
                  onChanged: (query) {
                    if (query.trim().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListingScreen(
                            initialSearchQuery: query,
                          ),
                        ),
                      );
                    }
                  },
                  onFilterTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductListingScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 4. Editorial Campaign Hero
              _buildEditorialHero(),

              const SizedBox(height: 24),

              // 5. Curated Categories Section
              _buildCategoriesSection(),

              const SizedBox(height: 24),

              // 6. The Beauty Edit Carousel
              _buildBeautyEditSection(),

              const SizedBox(height: 24),

              // 7. Daily Ritual Section
              _buildDailyRitualSection(),

              const SizedBox(height: 24),

              // 8. New Arrival Drop Card
              _buildNewArrivalSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Image.network(
                  AppConstants.fallbackLogoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.spa_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.titleLg(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Home',
                    style: AppTextStyles.headlineSm().copyWith(
                      fontSize: 18,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  backgroundImage: NetworkImage(AppConstants.fallbackAvatarUrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Greeting & Sync Pill ---
  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Good morning, $_userName',
                    style: AppTextStyles.headlineSm().copyWith(fontSize: 19),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  size: 13,
                  color: AppColors.onSecondaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'SQLite Ready',
                  style: AppTextStyles.labelSm(
                    color: AppColors.onSecondaryContainer,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Editorial Hero Banner ---
  Widget _buildEditorialHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 340,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A702D46),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                AppConstants.fallbackHeroImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.tertiaryContainer,
                  child: const Center(
                    child: Icon(Icons.spa_rounded, size: 64, color: AppColors.surface),
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.inverseSurface.withValues(alpha: 0.35),
                      AppColors.inverseSurface.withValues(alpha: 0.90),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'EDITORIAL EXCLUSIVE',
                          style: AppTextStyles.labelSm(
                            color: AppColors.inverseOnSurface,
                          ).copyWith(letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Headline Text
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.displayLg(
                        color: AppColors.inverseOnSurface,
                      ).copyWith(fontSize: 26, height: 1.2),
                      children: const [
                        TextSpan(text: 'Your skin, in its '),
                        TextSpan(
                          text: 'glow era',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Discover the iconic Rosehip & Niacinamide Dew Concentrate for effortless radiance.',
                    style: AppTextStyles.bodySm(
                      color: AppColors.inverseOnSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Primary CTA Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListingScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EXPLORE COLLECTION',
                          style: AppTextStyles.labelLg(color: AppColors.onPrimary).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Curated Categories ---
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Curated Categories',
                style: AppTextStyles.titleMd(),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductListingScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Browse All',
                  style: AppTextStyles.labelMd(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductListingScreen(
                        categoryId: cat.id,
                        categoryName: cat.name,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A702D46),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(cat.iconName),
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      style: AppTextStyles.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- The Beauty Edit Carousel ---
  Widget _buildBeautyEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Beauty Edit',
                    style: AppTextStyles.headlineMd(),
                  ),
                  Text(
                    'Iconic bestsellers crafted for luminous moisture',
                    style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductListingScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: AppTextStyles.labelMd(color: AppColors.primary),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 310,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _featuredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              final productId = product.id;
              final isFav = _wishlistedIds.contains(productId);

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
                  final nowWishlisted = await _wishlistRepository.toggleWishlist(productId);
                  if (!mounted) return;
                  setState(() {
                    if (nowWishlisted) {
                      _wishlistedIds.add(productId);
                    } else {
                      _wishlistedIds.remove(productId);
                    }
                  });
                },
                onQuickAddTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _cartRepository.addToCart(productId, quantity: 1);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.title} to Shopping Bag!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Daily Ritual Section ---
  Widget _buildDailyRitualSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D702D46),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    const SizedBox(width: 6),
                    Text(
                      'RITUAL GUIDE',
                      style: AppTextStyles.labelSm(color: AppColors.primary).copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '3 Steps',
                    style: AppTextStyles.labelSm(
                      color: AppColors.onSecondaryContainer,
                    ).copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your Daily Ritual',
              style: AppTextStyles.headlineSm(),
            ),
            const SizedBox(height: 4),
            Text(
              'Three intentional steps to gently restore, hydrate, and seal in luminous radiance.',
              style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            // Step 1
            _buildRitualStepItem(
              stepIndex: 0,
              stepNum: '01',
              title: 'Gentle Milky Cleanser',
              subtitle: 'Melt impurities without stripping hydration',
              icon: Icons.clean_hands_rounded,
            ),
            const SizedBox(height: 10),
            // Step 2
            _buildRitualStepItem(
              stepIndex: 1,
              stepNum: '02',
              title: 'Hydra-Plump Essence',
              subtitle: 'Micro-hyaluronic barrier replenishment',
              icon: Icons.water_drop_rounded,
            ),
            const SizedBox(height: 10),
            // Step 3
            _buildRitualStepItem(
              stepIndex: 2,
              stepNum: '03',
              title: 'Dewy SPF 50 Shield',
              subtitle: 'Lightweight broad-spectrum finish',
              icon: Icons.wb_sunny_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRitualStepItem({
    required int stepIndex,
    required String stepNum,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDone = _completedRitualSteps.contains(stepIndex);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isDone) {
            _completedRitualSteps.remove(stepIndex);
          } else {
            _completedRitualSteps.add(stepIndex);
          }
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !isDone
                  ? 'Completed Step $stepNum: $title'
                  : 'Unchecked Step $stepNum: $title',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.outlineVariant.withValues(alpha: 0.3),
            width: isDone ? 1.2 : 1,
          ),
          boxShadow: [
            if (isDone)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                stepNum,
                style: AppTextStyles.headlineSm(
                  color: isDone ? AppColors.primary : AppColors.outlineVariant,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primaryFixed
                    : AppColors.secondaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDone
                    ? AppColors.onPrimaryFixedVariant
                    : AppColors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMd().copyWith(fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isDone ? AppColors.primary : AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  // --- New Arrival ---
  Widget _buildNewArrivalSection() {
    final String title = _newArrivalProduct?.title ?? 'Rose Quartz Gua Sha & Facial Oil';
    final String subtitle = _newArrivalProduct?.subtitle ?? 'Sculpts & deeply locks in moisture';
    final int price = _newArrivalProduct?.price ?? 6500;
    final String badge = _newArrivalProduct?.badgeText ?? 'Self-Care Set';
    final String imageUrl = _newArrivalProduct?.imageUrl ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCLHVfmRJmMIYmthTj5-AEe-0l4e2Tko5veXpw82imIOfTpqdckWUZArM3GKcr_oK70vIpCQrv5eSz6cHWj4ngetvnPWWCu0r_jnrxHMWszGiusPEtGwJysuGYndLJWpnOSGid46m5k_GtCQ-JJYl9Y7qe4mddUvuJl0tbDsDA9GXDQfjD_llDhKR-urlLQSVC4hxz73GkPYyJl_HsYFKVOIZPIcj1ZOgd9fU_N-RIBj7vAvxnyFwufyQ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Arrival',
                style: AppTextStyles.headlineMd(),
              ),
              Text(
                'Limited Drop',
                style: AppTextStyles.labelMd(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (_newArrivalProduct != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(
                      productId: _newArrivalProduct!.id,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A702D46),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.spa_rounded, color: AppColors.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            badge,
                            style: AppTextStyles.labelSm(
                              color: AppColors.onSecondaryFixedVariant,
                            ).copyWith(fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: AppTextStyles.titleMd().copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppConstants.formatPrice(price),
                              style: AppTextStyles.priceMd(),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                if (_newArrivalProduct != null) {
                                  await _cartRepository.addToCart(_newArrivalProduct!.id, quantity: 1);
                                }
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Added $title to Shopping Bag!'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                              child: Text(
                                'Add to Bag',
                                style: AppTextStyles.labelSm(color: AppColors.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
