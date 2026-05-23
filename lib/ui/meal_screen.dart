import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/meal_provider.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedCategory = '';

  final List<Map<String, dynamic>> _quickCategories = [
    {'name': 'Chicken', 'icon': Icons.restaurant},
    {'name': 'Beef', 'icon': Icons.kebab_dining},
    {'name': 'Dessert', 'icon': Icons.cake},
    {'name': 'Seafood', 'icon': Icons.set_meal},
    {'name': 'Vegetarian', 'icon': Icons.grass},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MealProvider>().fetchRandomMeal();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _isSearching = val.isNotEmpty;
      if (val.isNotEmpty) {
        _selectedCategory = '';
      }
    });
    if (val.isNotEmpty) {
      context.read<MealProvider>().searchMeals(val);
    }
  }

  void _selectCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = '';
        _isSearching = false;
        _searchController.clear();
      } else {
        _selectedCategory = category;
        _isSearching = true;
        _searchController.text = category;
        context.read<MealProvider>().searchMeals(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'EPICUREAN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 20,
            color: Color(0xFF1E1E2C),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.amber),
            tooltip: 'Refresh Recipes',
            onPressed: () {
              if (_isSearching && _searchController.text.isNotEmpty) {
                context.read<MealProvider>().searchMeals(
                  _searchController.text,
                  ars: ARS(refresh: true),
                );
              } else {
                context.read<MealProvider>().fetchRandomMeal(
                  ars: ARS(refresh: true),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Search and Categories Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exquisite recipes...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.amber,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearching = false;
                                _selectedCategory = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),
                const Text(
                  'POPULAR CATEGORIES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickCategories.length,
                    itemBuilder: (context, index) {
                      final cat = _quickCategories[index];
                      final name = cat['name'] as String;
                      final icon = cat['icon'] as IconData;
                      final isSelected = _selectedCategory == name;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            icon,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : Colors.amber.shade700,
                          ),
                          label: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _selectCategory(name),
                          selectedColor: Colors.amber,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          backgroundColor: const Color(0xFFF7F9FC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide.none,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Body
          Expanded(
            child: _isSearching
                ? LikeBuilder<List<MealModel>>(
                    observe: () => mealProvider.searchResponse,
                    onSuccess: (meals, isRefreshing, isFromSWR) {
                      if (meals.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.no_meals_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recipes found for "${_searchController.text}"',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          RefreshIndicator(
                            color: Colors.amber,
                            onRefresh: () async {
                              await context.read<MealProvider>().searchMeals(
                                _searchController.text,
                                ars: ARS(
                                  refresh: true,
                                ), //refresh true to ignore api loading state
                              );
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: meals.length,
                              itemBuilder: (context, index) {
                                final meal = meals[index];
                                return _buildMealCard(meal);
                              },
                            ),
                          ),
                          if (isRefreshing)
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: Colors.amber,
                              ),
                            ),
                        ],
                      );
                    },
                    onLoading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                    onError: (error) =>
                        Center(child: Text('Error: ${error.message}')),
                  )
                : LikeBuilder<List<MealModel>>(
                    observe: () => mealProvider.randomMealResponse,
                    onSuccess: (meals, isRefreshing, isFromSWR) {
                      if (meals.isEmpty) {
                        return const Center(
                          child: Text('No daily recipe available.'),
                        );
                      }
                      final meal = meals.first;
                      return Stack(
                        children: [
                          RefreshIndicator(
                            color: Colors.amber,
                            onRefresh: () async {
                              await context.read<MealProvider>().fetchRandomMeal(
                                ars: ARS(
                                  refresh: true,
                                ), //refresh true to ignore api loading state
                              );
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'CRAFTED FOR YOU TODAY',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDailyFeaturedCard(meal),
                                ],
                              ),
                            ),
                          ),
                          if (isRefreshing)
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: Colors.amber,
                              ),
                            ),
                        ],
                      );
                    },
                    onLoading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                    onError: (error) =>
                        Center(child: Text('Error: ${error.message}')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyFeaturedCard(MealModel meal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              LikeCacheImage(
                imageUrl: meal.thumbUrl,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  height: 260,
                  color: Colors.grey.shade100,
                  child: const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withAlpha(200), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            color: Colors.amber.shade200,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            meal.category.toUpperCase(),
                            style: TextStyle(
                              color: Colors.amber.shade200,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.public_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Origin: ${meal.area}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'PREPARATION INSTRUCTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meal.instructions,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _navigateToDetails(meal),
                    child: const Text(
                      'VIEW FULL RECIPE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
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

  Widget _buildMealCard(MealModel meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LikeCacheImage(
              imageUrl: meal.thumbUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade100,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          title: Text(
            meal.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF1E1E2C),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•  ${meal.area}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey,
          ),
          onTap: () => _navigateToDetails(meal),
        ),
      ),
    );
  }

  void _navigateToDetails(MealModel meal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MealDetailScreen(meal: meal)),
    );
  }
}

class MealDetailScreen extends StatelessWidget {
  final MealModel meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  LikeCacheImage(
                    imageUrl: meal.thumbUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          meal.category.toUpperCase(),
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.public_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            meal.area,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E2C),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    'INSTRUCTIONS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meal.instructions,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Color(0xFF4A4A6A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
