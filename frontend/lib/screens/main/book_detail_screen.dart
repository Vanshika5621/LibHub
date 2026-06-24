import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/book.dart';
import '../../widgets/premium_dialog.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final book = await context.read<AppState>().service.getBookById(widget.bookId);
      if (mounted) setState(() { _book = book; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _borrow() async {
    setState(() => _actionLoading = true);
    final result = await context.read<AppState>().borrowBook(widget.bookId);
    if (mounted) {
      setState(() => _actionLoading = false);
      if (result['success'] == true) {
        PremiumDialog.show(
          context: context,
          title: 'Happy Reading! 📖',
          message: 'The book has been added to your borrowed list. Enjoy!',
          icon: Icons.check_circle_rounded,
          iconColor: AppTheme.successColor,
          confirmText: 'Awesome',
        );
        _loadBook();
      } else {
        PremiumDialog.show(
          context: context,
          title: 'Borrow Failed',
          message: result['error'] ?? 'Could not borrow this book.',
          icon: Icons.error_outline_rounded,
          iconColor: AppTheme.errorColor,
        );
      }
    }
  }

  Future<void> _reserve() async {
    setState(() => _actionLoading = true);
    final result = await context.read<AppState>().reserveBook(widget.bookId);
    if (mounted) {
      setState(() => _actionLoading = false);
      if (result['success'] == true) {
        final pos = result['reserve']?['queue_position'] ?? '?';
        PremiumDialog.show(
          context: context,
          title: 'Reserved! 🔖',
          message: 'You have been added to the queue at position #$pos. We will notify you when it\'s ready.',
          icon: Icons.bookmark_added_rounded,
          iconColor: Colors.orange,
          confirmText: 'Got it',
        );
        _loadBook();
      } else {
        PremiumDialog.show(
          context: context,
          title: 'Reserve Failed',
          message: result['error'] ?? 'Could not reserve this book.',
          icon: Icons.error_outline_rounded,
          iconColor: AppTheme.errorColor,
        );
      }
    }
  }

  // Removed _showSnack as we now use PremiumDialog

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_book == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Book Details not found')));

    final book = _book!;
    final isWishlisted = state.wishlistIds.contains(book.id);
    final isAlreadyBorrowed = state.borrows.any((b) => b.bookId == book.id && b.status == 'active');
    final isAlreadyReserved = state.reserves.any((r) => r.bookId == book.id && (r.status == 'waiting' || r.status == 'ready'));

    return Scaffold(
      bottomNavigationBar: _buildBottomActions(state, isAlreadyBorrowed, isAlreadyReserved),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'book_${book.id}',
                child: book.coverImage != null && book.coverImage!.isNotEmpty
                    ? Image.network(book.coverImage!, fit: BoxFit.cover)
                    : Container(color: Colors.blueGrey, child: const Icon(Icons.book, size: 100, color: Colors.white)),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                onPressed: () => state.toggleWishlist(book.id),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _Badge(label: book.genre, color: AppTheme.primaryColor),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: AppTheme.secondaryColor, size: 20),
                      Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  Text(book.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('by ${book.author}', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  
                  // Metadata Grid
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _MetaItem(label: 'Pages', value: '${book.pages ?? 320}'),
                    _MetaItem(label: 'Language', value: book.language),
                    _MetaItem(label: 'Year', value: '${book.publishedYear ?? 2021}'),
                  ]),
                  
                  const SizedBox(height: 32),
                  const Text('About this book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    book.description ?? 'No description provided.',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6),
                  ),
                  const SizedBox(height: 100), // Extra space for FAB/BottomBar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppState state, bool borrowed, bool reserved) {
    if (!state.isLoggedIn) return const SizedBox.shrink();
    
    Color actionColor = AppTheme.primaryColor;
    if (borrowed) actionColor = AppTheme.successColor;
    if (reserved) actionColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          if (borrowed)
            const Expanded(child: _InfoBox(label: 'Already Borrowed', icon: Icons.library_books_rounded, color: AppTheme.successColor))
          else if (reserved)
            const Expanded(child: _InfoBox(label: 'On Waiting List', icon: Icons.timer_rounded, color: Colors.orange))
          else if (_book!.availableCopies > 0)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _actionLoading ? null : _borrow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _actionLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Borrow Now', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: OutlinedButton(
                  onPressed: _actionLoading ? null : _reserve,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _actionLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)) 
                      : const Text('Reserve Book', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label, value;
  const _MetaItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  ]);
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

class _InfoBox extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _InfoBox({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), 
      borderRadius: BorderRadius.circular(20), 
      border: Border.all(color: color.withOpacity(0.2), width: 1.5)
    ),
    alignment: Alignment.center,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    ),
  );
}
