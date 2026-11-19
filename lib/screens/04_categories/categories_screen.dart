import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../05_product_listing/product_listing_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final CategoryRepository? categoryRepository;

  const CategoriesScreen({
    super.key,
    this.categoryRepository,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoryRepository _categoryRepository;
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilterChip = 'All Formulations';

  final List<String> _filterChips = [
    'All Formulations',
    'Cruelty-Free',
    'Cold-Pressed',
    'Refillable',
  ];

  final Map<String, Map<String, String>> _categoryAssets = {
    'skincare': {
      'itemCount': '42 items',
      'subtitle': 'Serums, Cleansers & Creams',
      'tag': 'Routine Core',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAiF-VriMItcPqitlEOEcVrOVCiPGYrePiD-Ymwue8UXZpg11-TVY5DPoGl9A3W9WN72EhUqfwOnfeZllLGvgHTaCrwytvZFqvvMxQgM7egmRzhA0bpUyx6kYsERLOvNLzig8iMei1gRT6M0xA2DZUpxM4rKJSOCUS_fm7gPaFgTcN4rWDMkuZZfOQt4yLaSNJv2zf5W3iLIDMH5Xz4MhgxWdK5RiUtOxHxE-PswiKsd26yaS3p9MW5CQ',
    },
    'makeup': {
      'itemCount': '28 items',
      'subtitle': 'Luminous Tints, Lip Oils & Cheeks',
      'tag': 'Dewy Glow',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCxll1S4fiTvdLIl-3DxshPDISs7sGLMhw0xR-jOXv6Lhb9ILZf0L3JFaS9UYz7Mmq67hp98KqwndepjdiKY1NdrNOScJSsgK2e_ejqWassgN-7PFf8nr4jSKtHEm9XkEMR8u45aQ3wN5UrvSnutEtf01PusFRpfk2vqXQJtjl22I9cNoL5ovphomnKygrlJaSDp6xrNtGamp5rPjqvqLPtXhdmzeJ_rTX4-Cp6_Z2iogYyfJNWF0jW_A',
    },
    'haircare': {
      'itemCount': '18 items',
      'subtitle': 'Scalp Serums & Nourishing Elixirs',
      'tag': 'Follicle Care',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC3Px-GgJlcPF9MnUcXjxfuIBTBkVgLBuVzHad4hqJH6CqT9hjTsYYdKlm9h6oGJwVe50SbAzr9BoiBaGCACfg9ksEw_2zGGZnDUki5HJzMtgenu00KF26VHaQRyS3H6LraXPks5ATVPiTUXqKwhemt2zxgu-KdJ1rJYARczhMtTsPiGgjD43-d1z79LnOKLrb6vuor_1cmPQO7Zjyzjdr60n1lWlDSy25DjzxDLY0I9B3HTCbJAU4qfA',
    },
    'fragrance': {
      'itemCount': '14 items',
      'subtitle': 'Artisanal Eau de Parfum & Mists',
      'tag': 'Sensory Notes',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDRrIS62UyOZoAQlVebCJRAhUiWxfujqLAAUshGsKWdRaFvP3jUIgv8pSmRZIdqnTP6VmF40pIfs-bVSe24UJhlEBgQL-3Wq-iMKy0H6-n5sbn4_7A4M47r2dQ9xdnlkg5loSBAbzdAPFW_D6o1B7_CR2dIF8M4HlpBJPVrhQ-JNW2TJus1EQQGy75ZVd5aYSuP7BMeOUcGOhFxopydZh_5FBDs_8B2Ls861hfh43WE7QKsszHaFkzDMQ',
    },
    'body_care': {
      'itemCount': '22 items',
      'subtitle': 'Whipped Butters & Silk Scrubs',
      'tag': 'Full Restoration',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAi9elf1h3mv1tv7wcF8ZrYllrqTyWivvnzNMrJamSfjcKlOYWPkCbrMIY6Bkv7vN3Al6C0YxxJjj9SflJrV4I4GsOBpFJZqKjiYvngyrGI2EiKk2A_Cuq8HqP0GRNtniskqLfvgDr9Q9oazZrt0xLqqwJQcSZRrsw9zzAGhV3eeeLAUXScumKZfl4JImeQ9H46bzrovGfPTbd7uGBFi7sglfE409RQL3MY7r5OcnF-a8nwiQFPmOKULQ',
    },
  };

  @override
  void initState() {
    super.initState();
    _categoryRepository = widget.categoryRepository ?? CategoryRepository();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _filteredCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories';
          _isLoading = false;
        });
      }
    }
  }

  void _filterCategories(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredCategories = _allCategories;
      });
      return;
    }
    final String q = query.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories.where((c) {
        return c.name.toLowerCase().contains(q) ||
            (c.description ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // 1. Header Bar
              _buildHeader(context),

              // 2. Editorial Heading & Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CURATED BEAUTY ARCHIVES',
                          style: AppTextStyles.labelSm(color: AppColors.primary).copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Collections & Categories',
                      style: AppTextStyles.headlineLg(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore our curated botanical archives, tailored for conscious daily rituals.',
                      style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
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
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterCategories,
                          style: AppTextStyles.bodyMd(color: AppColors.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search botanicals, balms, tools...',
                            hintStyle: AppTextStyles.bodyMd(color: AppColors.outline),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _filterCategories('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.outline,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Horizontal Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterChips.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final chip = _filterChips[index];
                    final isSelected = _selectedFilterChip == chip;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterChip = chip;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          chip,
                          style: AppTextStyles.labelMd(
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 5. Category Grid / States
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: AppTextStyles.bodyMd()),
                        ElevatedButton(
                          onPressed: _fetchCategories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredCategories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No matching categories found.',
                      style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      final extra = _categoryAssets[category.id.toLowerCase()] ?? {
                        'itemCount': '15 items',
                        'subtitle': category.description ?? 'Botanical collection',
                        'tag': 'Curated',
                        'imageUrl':
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAiF-VriMItcPqitlEOEcVrOVCiPGYrePiD-Ymwue8UXZpg11-TVY5DPoGl9A3W9WN72EhUqfwOnfeZllLGvgHTaCrwytvZFqvvMxQgM7egmRzhA0bpUyx6kYsERLOvNLzig8iMei1gRT6M0xA2DZUpxM4rKJSOCUS_fm7gPaFgTcN4rWDMkuZZfOQt4yLaSNJv2zf5W3iLIDMH5Xz4MhgxWdK5RiUtOxHxE-PswiKsd26yaS3p9MW5CQ',
                      };

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductListingScreen(
                                categoryId: category.id,
                                categoryName: category.name,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D702D46),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Stack
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        extra['imageUrl']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: AppColors.surfaceContainerLow),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              AppColors.inverseSurface.withValues(alpha: 0.20),
                                              AppColors.inverseSurface.withValues(alpha: 0.85),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Count Badge
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          extra['itemCount']!,
                                          style: AppTextStyles.labelSm(color: AppColors.primary)
                                              .copyWith(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    // Title & Subtitle at bottom of image
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.name,
                                            style: AppTextStyles.headlineSm(
                                              color: AppColors.inverseOnSurface,
                                            ).copyWith(fontSize: 18),
                                          ),
                                          Text(
                                            extra['subtitle']!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodySm(
                                              color: AppColors.outlineVariant,
                                            ).copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Bottom Footer Bar
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                color: AppColors.surfaceContainerLowest,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      extra['tag']!,
                                      style: AppTextStyles.labelSm(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // 6. Seasonal Spotlight Banner Card
              _buildSeasonalSpotlight(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

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
                    'Categories',
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

  Widget _buildSeasonalSpotlight() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D702D46),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.spa_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'SEASONAL SPOTLIGHT',
                        style: AppTextStyles.labelSm(color: AppColors.primary).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Edition 04',
                  style: AppTextStyles.labelSm(color: AppColors.onSecondaryFixedVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Winter Radiance Guide',
              style: AppTextStyles.headlineMd(color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Shield your skin barrier against crisp winter winds with peptide-rich lipid layers and soothing camellia nectar.',
              style: AppTextStyles.bodyMd(color: AppColors.onSecondaryFixedVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '6',
                              style: AppTextStyles.labelSm(color: AppColors.onPrimary)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curated Ceremony Steps',
                                style: AppTextStyles.labelMd(color: AppColors.onSurface)
                                    .copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '15 min holistic ritual',
                                style: AppTextStyles.bodySm(color: AppColors.onSecondaryFixedVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Winter Radiance Guide')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: Text(
                      'Read Guide',
                      style: AppTextStyles.labelSm(color: AppColors.onPrimary),
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
}
