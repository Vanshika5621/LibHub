import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/book.dart';

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
      final msg = result['success'] == true
          ? '✅ Book borrowed successfully!'
          : '❌ ${result['error'] ?? 'Request failed'}';
      _showSnack(msg, result['success'] == true);
      if (result['success'] == true) _loadBook();
    }
  }

  Future<void> _reserve() async {
    setState(() => _actionLoading = true);
    final result = await context.read<AppState>().reserveBook(widget.bookId);
    if (mounted) {
      setState(() => _actionLoading = false);
      final msg = result['success'] == true
          ? '✅ Reserved! You are #${result['queuePosition']} in queue.'
          : '❌ ${result['error'] ?? 'Request failed'}';
      _showSnack(msg, result['success'] == true);
      if (result['success'] == true) _loadBook();
    }
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

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
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (borrowed)
            const Expanded(child: _InfoBox(label: 'Borrowed', color: Colors.green))
          else if (reserved)
            const Expanded(child: _InfoBox(label: 'Reserved', color: Colors.orange))
          else if (_book!.availableCopies > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _actionLoading ? null : _borrow,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _actionLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Borrow for Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Expanded(
              child: OutlinedButton(
                onPressed: _actionLoading ? null : _reserve,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.orange, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _actionLoading ? const CircularProgressIndicator() : const Text('Reserve (Out of Stock)', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
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
  const _InfoBox({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color)),
    alignment: Alignment.center,
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
  );
}
