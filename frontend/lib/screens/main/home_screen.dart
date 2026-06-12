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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
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
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Updated Premium Header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 56, 16, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        state.isLoggedIn
                                            ? '${state.profile?.membershipTier.toUpperCase() ?? "FREE"} MEMBER'
                                            : 'GUEST',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.isLoggedIn)
                                  Hero(
                                    tag: 'profile_pic',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white24,
                                        child: Text(
                                          state.profile != null && state.profile!.firstName.isNotEmpty ? state.profile!.firstName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              state.isLoggedIn
                                  ? _getTimeBasedGreeting(state.profile?.firstName ?? 'Reader')
                                  : 'Welcome to LibHub',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What will you read today?',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            // Improved Search Bar
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                                ],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(color: Colors.black87, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Search for books...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E3192)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onSubmitted: (v) {
                                  if (v.trim().isNotEmpty) {
                                    state.searchFromDashboard(v.trim());
                                    _searchCtrl.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Stats & Stats section
            if (state.isLoggedIn)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _StatSquare(icon: Icons.bookmark_added, label: 'Borrowed', value: state.activeBorrowsCount.toString(), color: const Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      _StatSquare(icon: Icons.favorite_rounded, label: 'Wishlist', value: state.wishlistIds.length.toString(), color: const Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      _StatSquare(icon: Icons.access_time_filled, label: 'Reserves', value: state.activeReservesCount.toString(), color: const Color(0xFFF59E0B)),
                    ],
                  ),
                ),
              ),

            // Main Sections
            const _SectionHeader(title: '🔥 Trending Now', icon: Icons.whatshot, color: Colors.orange),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
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

            const _SectionHeader(title: '✨ Just Added', icon: Icons.new_releases, color: Colors.blue),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
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

             const _SectionHeader(title: 'Reading Progress', icon: Icons.auto_stories, color: Colors.green),
             if (state.isLoggedIn && goal != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
                  ),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 35,
                        lineWidth: 8,
                        percent: goal.yearlyProgress,
                        center: Text("${(goal.yearlyProgress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                        progressColor: const Color(0xFF2E3192),
                        backgroundColor: Colors.grey.shade100,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Yearly Goal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${goal.booksReadYear} of ${goal.yearlyGoal} books read', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _StatSquare extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatSquare({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const Spacer(),
            TextButton(
              onPressed: () => context.read<AppState>().setTabIndex(1),
              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.bold)),
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

  const _BookCard({required this.book, required this.isWishlisted, this.onWishlistToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      book.coverImage != null && book.coverImage!.isNotEmpty
                          ? Image.network(book.coverImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                          : _buildPlaceholder(),
                      if (onWishlistToggle != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: InkWell(
                            onTap: onWishlistToggle,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                              child: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(book.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(book.author, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Center(child: Icon(Icons.book_rounded, color: Colors.blueGrey, size: 48)),
    );
  }
}
