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
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  void _applyFilters() {
    context.read<AppState>().reloadBooks(
      query: _query, genre: _genre, onlyAvailable: _onlyAvailable, sortBy: _sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by title or author...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); _applyFilters(); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: (v) { setState(() => _query = v); _applyFilters(); },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // Genre Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _genre != 'All' ? AppTheme.primaryColor.withOpacity(0.1) : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _genre != 'All' ? AppTheme.primaryColor : theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _genre,
                      isDense: true,
                      style: TextStyle(fontSize: 13, color: _genre != 'All' ? AppTheme.primaryColor : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: _genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) { setState(() => _genre = v!); _applyFilters(); },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isDense: true,
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color, fontFamily: 'Inter'),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: _sortOptions.map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!))).toList(),
                      onChanged: (v) { setState(() => _sortBy = v!); _applyFilters(); },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Available filter chip
                FilterChip(
                  label: const Text('Available Only', style: TextStyle(fontSize: 12)),
                  selected: _onlyAvailable,
                  onSelected: (v) { setState(() => _onlyAvailable = v); _applyFilters(); },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(color: _onlyAvailable ? AppTheme.primaryColor : null, fontWeight: _onlyAvailable ? FontWeight.w600 : null),
                  side: BorderSide(color: _onlyAvailable ? AppTheme.primaryColor : theme.dividerColor),
                  backgroundColor: theme.cardColor,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ),
          // Book Grid
          Expanded(
            child: state.isLoading && state.books.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : state.books.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.search_off_rounded, size: 64, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(height: 12),
                          const Text('No books found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Try adjusting your search or filters', style: theme.textTheme.bodyMedium),
                        ]),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.62,
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
}

class _CatalogBookCard extends StatelessWidget {
  final Book book;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;
  final VoidCallback onTap;
  const _CatalogBookCard({required this.book, required this.isWishlisted, this.onWishlistToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: book.coverImage != null
                        ? Image.network(book.coverImage!, fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            alignment: Alignment.center,
                            child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor, size: 48),
                          ),
                  ),
                  if (book.availableCopies == 0)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Unavailable', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (onWishlistToggle != null)
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: onWishlistToggle,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isWishlisted ? AppTheme.errorColor : Colors.white, size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(book.author, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppTheme.secondaryColor, size: 13),
                    const SizedBox(width: 3),
                    Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(book.genre, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
