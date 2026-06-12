import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/book.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getTimeBasedGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, $name! ☕';
    } else if (hour < 17) {
      return 'Good Afternoon, $name! ☀️';
    } else {
      return 'Good Evening, $name! 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final goal = state.readingGoal;

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => state.loadUserData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Premium Header / Greet
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 56, 16, 12),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppTheme.secondaryColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                state.isLoggedIn
                                    ? '${state.profile?.membershipTier.toString().toUpperCase()} Member'
                                    : 'Guest Mode',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (state.isLoggedIn)
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              state.profile != null && state.profile!.firstName.isNotEmpty
                                  ? state.profile!.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.isLoggedIn
                          ? _getTimeBasedGreeting(state.profile?.firstName ?? 'Reader')
                          : 'Welcome to LibHub 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find your next favorite book and read anywhere.',
                      style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    // Glassmorphic Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search books, authors, genres...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            state.searchFromDashboard(val.trim());
                            _searchCtrl.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reading Goal Progress Widget
            if (state.isLoggedIn && goal != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 28,
                        lineWidth: 6,
                        percent: goal.yearlyProgress,
                        center: Text(
                          '${(goal.yearlyProgress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        progressColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Yearly Reading Goal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have read ${goal.booksReadYear} out of ${goal.yearlyGoal} books this year.',
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => state.setTabIndex(4), // navigate to profile
                      ),
                    ],
                  ),
                ),
              ),

            // Quick Actions Shortcut Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionTile(
                      icon: Icons.explore_rounded,
                      label: 'Explore',
                      color: AppTheme.primaryColor,
                      onTap: () => state.setTabIndex(1),
                    ),
                    _QuickActionTile(
                      icon: Icons.forum_rounded,
                      label: 'Ask AI',
                      color: Colors.purple,
                      onTap: () => state.setTabIndex(3),
                    ),
                    _QuickActionTile(
                      icon: Icons.book_rounded,
                      label: 'Borrowed',
                      color: AppTheme.successColor,
                      onTap: () => state.setTabIndex(2),
                    ),
                    _QuickActionTile(
                      icon: Icons.card_membership_rounded,
                      label: 'Upgrade',
                      color: AppTheme.secondaryColor,
                      onTap: () {
                        // Switch to Profile or upgrade directly
                        state.setTabIndex(4);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats Bar
            if (state.isLoggedIn)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      _StatCard(label: 'Borrowed', value: '${state.activeBorrowsCount}', color: AppTheme.primaryColor, icon: Icons.library_books_rounded),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Wishlist', value: '${state.wishlistIds.length}', color: AppTheme.successColor, icon: Icons.favorite_rounded),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Reserves', value: '${state.activeReservesCount}', color: AppTheme.secondaryColor, icon: Icons.bookmark_rounded),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Fines',
                        value: '${state.unpaidFinesCount}',
                        color: AppTheme.errorColor,
                        icon: Icons.warning_rounded,
                        onTap: () {
                          // navigate to profile to show fines dialog
                          state.setTabIndex(4);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Trending Section
            if (state.books.isNotEmpty) ...[
              const _SectionHeader(title: 'Trending Books', icon: Icons.local_fire_department_rounded, color: Colors.orange),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.books.where((b) => b.isTrending).length,
                    itemBuilder: (ctx, i) {
                      final list = state.books.where((b) => b.isTrending).toList();
                      return _BookCard(
                        book: list[i],
                        isWishlisted: state.wishlistIds.contains(list[i].id),
                        onWishlistToggle: state.isLoggedIn ? () => state.toggleWishlist(list[i].id) : null,
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: list[i].id))),
                      );
                    },
                  ),
                ),
              ),
            ],

            // New Arrivals Section
            if (state.books.isNotEmpty) ...[
              const _SectionHeader(title: 'New Arrivals', icon: Icons.auto_awesome_rounded, color: AppTheme.secondaryColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.books.where((b) => b.isNewArrival).length,
                    itemBuilder: (ctx, i) {
                      final list = state.books.where((b) => b.isNewArrival).toList();
                      return _BookCard(
                        book: list[i],
                        isWishlisted: state.wishlistIds.contains(list[i].id),
                        onWishlistToggle: state.isLoggedIn ? () => state.toggleWishlist(list[i].id) : null,
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: list[i].id))),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Membership Section
            const _SectionHeader(title: 'Membership Plans', icon: Icons.workspace_premium_rounded, color: AppTheme.secondaryColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(
                  children: [
                    _PlanCard(
                      name: 'Free',
                      price: 0,
                      tier: 'free',
                      features: const ['2 books at a time', '7-day borrow period', 'Basic search'],
                      isCurrentTier: state.profile?.membershipTier == 'free',
                      onUpgrade: () {},
                    ),
                    const SizedBox(height: 12),
                    _PlanCard(
                      name: 'Premium',
                      price: 299,
                      tier: 'premium',
                      features: const ['5 books at a time', '21-day borrow period', 'Priority reserves', 'No Ads'],
                      isCurrentTier: state.profile?.membershipTier == 'premium',
                      isHighlighted: true,
                      onUpgrade: () => state.upgradeMembership('premium', 299.00, context),
                    ),
                    const SizedBox(height: 12),
                    _PlanCard(
                      name: 'VIP',
                      price: 599,
                      tier: 'vip',
                      features: const ['Unlimited books', '30-day borrow period', '2 fine waivers/month', 'Personalized AI recommendations'],
                      isCurrentTier: state.profile?.membershipTier == 'vip',
                      onUpgrade: () => state.upgradeMembership('vip', 599.00, context),
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.24), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.isWishlisted,
    this.onWishlistToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: book.coverImage != null
                        ? Image.network(
                            book.coverImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              alignment: Alignment.center,
                              child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor, size: 36),
                            ),
                          )
                        : Container(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            alignment: Alignment.center,
                            child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor, size: 36),
                          ),
                  ),
                  if (book.availableCopies == 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Out of Stock', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (onWishlistToggle != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onWishlistToggle,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isWishlisted ? AppTheme.errorColor : Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.secondaryColor, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        book.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
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

class _PlanCard extends StatelessWidget {
  final String name;
  final int price;
  final String tier;
  final List<String> features;
  final bool isHighlighted;
  final bool isCurrentTier;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.tier,
    required this.features,
    this.isHighlighted = false,
    required this.isCurrentTier,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.04) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.4) : theme.dividerColor,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$name Plan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isCurrentTier)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Active Plan', style: TextStyle(color: AppTheme.successColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: price == 0 ? 'Free' : '₹$price',
              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              children: price > 0
                  ? [TextSpan(text: '/month', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.normal))]
                  : [],
            ),
          ),
          const Divider(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 15),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isCurrentTier
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.transparent)),
                    child: const Text('Current Plan'),
                  )
                : isHighlighted
                    ? ElevatedButton(
                        onPressed: price == 0 ? null : onUpgrade,
                        child: Text(price == 0 ? 'Free Access' : 'Upgrade to $name'),
                      )
                    : OutlinedButton(
                        onPressed: price == 0 ? null : onUpgrade,
                        child: Text(price == 0 ? 'Free Access' : 'Upgrade to $name'),
                      ),
          ),
        ],
      ),
    );
  }
}
