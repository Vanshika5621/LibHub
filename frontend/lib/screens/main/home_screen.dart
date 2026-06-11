import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/book.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => state.loadUserData(),
        child: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Digital Library', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.isLoggedIn
                              ? 'Hello, ${state.profile?.firstName ?? 'Reader'}! 👋'
                              : 'Welcome to LibHub',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Discover, borrow & enjoy thousands of books.',
                          style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _HeroButton(label: 'Browse Books', icon: Icons.menu_book_rounded, onTap: () {}),
                            if (state.isLoggedIn) ...[
                              const SizedBox(width: 10),
                              _HeroBadgeButton(
                                label: _membershipLabel(state.profile?.membershipTier ?? 'free'),
                                icon: Icons.workspace_premium_rounded,
                                onTap: () {},
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats
            if (state.isLoggedIn)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      _StatCard(label: 'Borrowed', value: '${state.activeBorrowsCount}', color: AppTheme.primaryColor, icon: Icons.library_books_rounded),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Wishlist', value: '${state.wishlistIds.length}', color: AppTheme.successColor, icon: Icons.favorite_rounded),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Reserves', value: '${state.activeReservesCount}', color: AppTheme.secondaryColor, icon: Icons.bookmark_rounded),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Fines', value: '${state.unpaidFinesCount}', color: AppTheme.errorColor, icon: Icons.warning_rounded),
                    ],
                  ),
                ),
              ),

            // Trending Books
            if (state.trendingBooks.isNotEmpty) ...[
              _SectionHeader(title: 'Trending Books', icon: Icons.trending_up_rounded, color: AppTheme.primaryColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.trendingBooks.length,
                    itemBuilder: (ctx, i) => _BookCard(
                      book: state.trendingBooks[i],
                      isWishlisted: state.wishlistIds.contains(state.trendingBooks[i].id),
                      onWishlistToggle: state.isLoggedIn ? () => state.toggleWishlist(state.trendingBooks[i].id) : null,
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: state.trendingBooks[i].id))),
                    ),
                  ),
                ),
              ),
            ],

            // New Arrivals
            if (state.newArrivals.isNotEmpty) ...[
              _SectionHeader(title: 'New Arrivals', icon: Icons.auto_awesome_rounded, color: AppTheme.secondaryColor),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.newArrivals.length,
                    itemBuilder: (ctx, i) => _BookCard(
                      book: state.newArrivals[i],
                      isWishlisted: state.wishlistIds.contains(state.newArrivals[i].id),
                      onWishlistToggle: state.isLoggedIn ? () => state.toggleWishlist(state.newArrivals[i].id) : null,
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: state.newArrivals[i].id))),
                    ),
                  ),
                ),
              ),
            ],

            // Membership Plans
            _SectionHeader(title: 'Membership Plans', icon: Icons.workspace_premium_rounded, color: const Color(0xFFD97706)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  children: [
                    _PlanCard(name: 'Free', price: 0, tier: 'free', features: ['2 books at a time', '7-day borrow period', 'Basic search'], isCurrentTier: state.profile?.membershipTier == 'free'),
                    const SizedBox(height: 12),
                    _PlanCard(name: 'Premium', price: 299, tier: 'premium', features: ['5 books at a time', '21-day borrow period', 'Priority reserves', 'No ads'], isHighlighted: true, isCurrentTier: state.profile?.membershipTier == 'premium'),
                    const SizedBox(height: 12),
                    _PlanCard(name: 'VIP', price: 599, tier: 'vip', features: ['Unlimited books', '30-day borrow period', '2 fine waivers/month', 'AI recommendations'], isCurrentTier: state.profile?.membershipTier == 'vip'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _membershipLabel(String tier) {
    switch (tier) {
      case 'premium': return 'Premium';
      case 'vip': return 'VIP';
      default: return 'Free Plan';
    }
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeroButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _HeroBadgeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeroBadgeButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  const _BookCard({required this.book, required this.isWishlisted, this.onWishlistToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: book.coverImage != null
                        ? Image.network(book.coverImage!, fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            alignment: Alignment.center,
                            child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor, size: 40),
                          ),
                  ),
                  if (book.availableCopies == 0)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Unavailable', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (onWishlistToggle != null)
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: onWishlistToggle,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isWishlisted ? AppTheme.errorColor : Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: theme.textTheme.labelLarge?.copyWith(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(book.author, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.secondaryColor, size: 12),
                      const SizedBox(width: 3),
                      Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
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
  const _PlanCard({required this.name, required this.price, required this.tier, required this.features, this.isHighlighted = false, required this.isCurrentTier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.06) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.5) : theme.dividerColor,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(name, style: theme.textTheme.titleLarge?.copyWith(fontSize: 17)),
            const Spacer(),
            if (isCurrentTier)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Current', style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: price == 0 ? 'Free' : '₹$price',
              style: TextStyle(color: AppTheme.primaryColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              children: price > 0 ? [TextSpan(text: '/month', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.normal))] : [],
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 15),
              const SizedBox(width: 8),
              Text(f, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
            ]),
          )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isHighlighted
                ? ElevatedButton(onPressed: () {}, child: Text(isCurrentTier ? 'Current Plan' : 'Upgrade to $name'))
                : OutlinedButton(onPressed: () {}, child: Text(isCurrentTier ? 'Current Plan' : (price == 0 ? 'Free Plan' : 'Upgrade'))),
          ),
        ],
      ),
    );
  }
}
