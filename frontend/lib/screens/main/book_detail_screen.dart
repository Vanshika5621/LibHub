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
  String? _actionResult;
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
    setState(() { _actionLoading = true; _actionResult = null; });
    final result = await context.read<AppState>().borrowBook(widget.bookId);
    if (mounted) {
      setState(() => _actionLoading = false);
      final msg = result['success'] == true
          ? '✅ Book borrowed! Due: ${_formatDate(result['dueDate'])}'
          : '❌ ${result['error'] ?? 'Something went wrong'}';
      _showSnack(msg, result['success'] == true);
      if (result['success'] == true) _loadBook();
    }
  }

  Future<void> _reserve() async {
    setState(() { _actionLoading = true; _actionResult = null; });
    final result = await context.read<AppState>().reserveBook(widget.bookId);
    if (mounted) {
      setState(() => _actionLoading = false);
      final msg = result['success'] == true
          ? '✅ Reserved! Queue position: #${result['queuePosition']}'
          : '❌ ${result['error'] ?? 'Something went wrong'}';
      _showSnack(msg, result['success'] == true);
    }
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return raw.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    if (_book == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Book not found')));

    final book = _book!;
    final isWishlisted = state.wishlistIds.contains(book.id);
    final isAlreadyBorrowed = state.borrows.any((b) => b.bookId == book.id && b.status == 'active');
    final isAlreadyReserved = state.reserves.any((r) => r.bookId == book.id && (r.status == 'waiting' || r.status == 'ready'));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible AppBar with cover image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isWishlisted ? AppTheme.errorColor : Colors.white,
                ),
                onPressed: state.isLoggedIn ? () => state.toggleWishlist(book.id) : null,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: book.coverImage != null
                  ? Image.network(book.coverImage!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF7C3AED)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 80),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genre + availability badges
                  Row(children: [
                    _Badge(label: book.genre, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    _Badge(
                      label: book.availableCopies > 0 ? '${book.availableCopies} Available' : 'Unavailable',
                      color: book.availableCopies > 0 ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(book.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('by ${book.author}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15)),
                  const SizedBox(height: 12),
                  // Rating Row
                  Row(children: [
                    ...List.generate(5, (i) => Icon(
                      i < book.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.secondaryColor, size: 20,
                    )),
                    const SizedBox(width: 8),
                    Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('(${book.ratingCount} ratings)', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                  ]),
                  const SizedBox(height: 20),

                  // Action Buttons
                  if (state.isLoggedIn) ...[
                    if (isAlreadyBorrowed)
                      const _InfoBanner(label: 'You have borrowed this book', icon: Icons.check_circle_rounded, color: AppTheme.successColor)
                    else if (book.availableCopies > 0)
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _actionLoading ? null : _borrow,
                          icon: _actionLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download_done_rounded),
                          label: const Text('Borrow Now'),
                        ),
                      )
                    else if (isAlreadyReserved)
                      const _InfoBanner(label: 'You have reserved this book', icon: Icons.bookmark_rounded, color: AppTheme.secondaryColor)
                    else
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _actionLoading ? null : _reserve,
                          icon: _actionLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bookmark_add_rounded),
                          label: const Text('Reserve Book'),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ] else
                    const _InfoBanner(label: 'Sign in to borrow or reserve this book', icon: Icons.login_rounded, color: AppTheme.primaryColor),

                  const SizedBox(height: 20),
                  // Book Info
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('About this book', style: theme.textTheme.titleLarge?.copyWith(fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(book.description ?? 'No description available.', style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 15)),
                  const SizedBox(height: 24),
                  // Metadata
                  _MetaRow(label: 'Publisher', value: book.publisher ?? 'Unknown'),
                  _MetaRow(label: 'Year', value: book.publishedYear?.toString() ?? '—'),
                  _MetaRow(label: 'Pages', value: book.pages?.toString() ?? '—'),
                  _MetaRow(label: 'Language', value: book.language),
                  _MetaRow(label: 'ISBN', value: book.isbn ?? '—'),
                  _MetaRow(label: 'Total Copies', value: '${book.totalCopies}'),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoBanner({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
