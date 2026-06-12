import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/book.dart';
import 'book_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _genre = 'All';
  bool _onlyAvailable = false;
  String _sortBy = 'rating';

  final List<String> _genres = ['All', 'Fiction', 'Non-Fiction', 'Science', 'History', 'Technology', 'Biography', 'Mystery', 'Fantasy', 'Romance', 'Self-Help', 'Business'];
  final List<Map<String, String>> _sortOptions = [
    {'value': 'rating', 'label': 'Top Rated'},
    {'value': 'new', 'label': 'Newest'},
    {'value': 'created_at', 'label': 'Latest Added'},
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _searchCtrl.text = state.catalogSearchQuery;
    _query = state.catalogSearchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  void _applyFilters() {
    final state = context.read<AppState>();
    state.setCatalogSearchQuery(_query);
    state.reloadBooks(
      query: _query, genre: _genre, onlyAvailable: _onlyAvailable, sortBy: _sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    if (_query != state.catalogSearchQuery) {
      _query = state.catalogSearchQuery;
      _searchCtrl.text = state.catalogSearchQuery;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Book Catalog', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 24)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Sleek Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by title, author...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); _applyFilters(); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) { setState(() => _query = v); _applyFilters(); },
              ),
            ),
          ),
          
          // Filters Row
          Container(
            height: 60,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: _genre == 'All' ? 'Genre' : _genre,
                  icon: Icons.category_rounded,
                  active: _genre != 'All',
                  onTap: () => _showGenrePicker(),
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  label: _sortOptions.firstWhere((o) => o['value'] == _sortBy)['label']!,
                  icon: Icons.sort_rounded,
                  active: true,
                  onTap: () => _showSortPicker(),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('Available'),
                  selected: _onlyAvailable,
                  onSelected: (v) { setState(() => _onlyAvailable = v); _applyFilters(); },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                  checkmarkColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),

          // Grid View
          Expanded(
            child: state.isLoading && state.books.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.books.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: state.books.length,
                        itemBuilder: (ctx, i) {
                          final book = state.books[i];
                          return _CatalogBookCard(
                            book: book,
                            isWishlisted: state.wishlistIds.contains(book.id),
                            onWishlistToggle: state.isLoggedIn ? () => state.toggleWishlist(book.id) : null,
                            onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required IconData icon, required bool active, required VoidCallback onTap}) {
    return ActionChip(
      onPressed: onTap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      avatar: Icon(icon, size: 16, color: active ? AppTheme.primaryColor : Colors.grey),
      label: Text(label, style: TextStyle(color: active ? AppTheme.primaryColor : Colors.black87, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: active ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? AppTheme.primaryColor : Colors.grey.shade200),
      ),
    );
  }

  void _showGenrePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _genres.map((g) => ListTile(
          title: Text(g),
          trailing: _genre == g ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
          onTap: () { setState(() => _genre = g); _applyFilters(); Navigator.pop(context); },
        )).toList(),
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _sortOptions.map((o) => ListTile(
          title: Text(o['label']!),
          trailing: _sortBy == o['value'] ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
          onTap: () { setState(() => _sortBy = o['value']!); _applyFilters(); Navigator.pop(context); },
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No matches found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try different keywords or filters.'),
        ],
      ),
    );
  }
}

class _CatalogBookCard extends StatelessWidget {
  final Book book;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;
  final VoidCallback onTap;

  const _CatalogBookCard({required this.book, required this.isWishlisted, this.onWishlistToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    book.coverImage != null && book.coverImage!.isNotEmpty
                        ? Image.network(book.coverImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                        : _buildPlaceholder(),
                    if (onWishlistToggle != null)
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: onWishlistToggle,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(book.author, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 1),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(child: Icon(Icons.book_rounded, color: Colors.grey, size: 40)),
    );
  }
}
