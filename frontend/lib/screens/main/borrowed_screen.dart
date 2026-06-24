import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/borrow.dart';
import '../../models/reserve.dart';
import '../../widgets/premium_dialog.dart';

class BorrowedScreen extends StatefulWidget {
  const BorrowedScreen({super.key});

  @override
  State<BorrowedScreen> createState() => _BorrowedScreenState();
}

class _BorrowedScreenState extends State<BorrowedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final activeBorrows = state.borrows.where((b) => b.status == 'active' || b.status == 'overdue').toList();
    final reserves = state.reserves.where((r) => r.status == 'waiting' || r.status == 'ready').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          tabs: [
            Tab(text: 'Borrowed (${activeBorrows.length})'),
            Tab(text: 'Reserved (${reserves.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await state.reloadBorrows();
          await state.reloadReserves();
        },
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            // Borrowed Tab
            activeBorrows.isEmpty
                ? const _EmptyState(icon: Icons.library_books_outlined, message: 'No active borrows', sub: 'Head to the catalog to borrow books')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeBorrows.length,
                    itemBuilder: (ctx, i) => _BorrowCard(borrow: activeBorrows[i]),
                  ),
            // Reserves Tab
            reserves.isEmpty
                ? const _EmptyState(icon: Icons.bookmark_outline_rounded, message: 'No active reserves', sub: 'Reserve an unavailable book from its detail page')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reserves.length,
                    itemBuilder: (ctx, i) => _ReserveCard(reserve: reserves[i]),
                  ),
          ],
        ),
      ),
    );
  }
}

class _BorrowCard extends StatefulWidget {
  final Borrow borrow;
  const _BorrowCard({required this.borrow});

  @override
  State<_BorrowCard> createState() => _BorrowCardState();
}

class _BorrowCardState extends State<_BorrowCard> {
  bool _loading = false;

  Future<void> _action(Future<Map<String, dynamic>> Function() action, String title, String successMsg, IconData icon, Color color) async {
    setState(() => _loading = true);
    final result = await action();
    if (mounted) {
      setState(() => _loading = false);
      final ok = result['success'] == true;
      PremiumDialog.show(
        context: context,
        title: ok ? title : 'Action Failed',
        message: ok ? successMsg : (result['error'] ?? 'An unexpected error occurred.'),
        icon: ok ? icon : Icons.error_outline_rounded,
        iconColor: ok ? color : AppTheme.errorColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrow = widget.borrow;
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final dark = AppTheme.isDarkMode(context);
    final dueDate = borrow.dueDate;
    final now = DateTime.now();
    final daysLeft = dueDate.difference(now).inDays;
    final isOverdue = borrow.isOverdue;
    final dueDateColor = isOverdue ? AppTheme.errorColor : (daysLeft <= 3 ? AppTheme.warningColor : AppTheme.successColor);

    final book = borrow.book;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? AppTheme.errorColor : Colors.black).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(
          color: isOverdue ? AppTheme.errorColor.withOpacity(0.3) : (dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: book?.coverImage != null
                        ? Image.network(book!.coverImage!, width: 70, height: 100, fit: BoxFit.cover)
                        : Container(
                            width: 70, height: 100,
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            alignment: Alignment.center,
                            child: const Icon(Icons.book, color: AppTheme.primaryColor),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ?? 'Unknown Book', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 4),
                      Text(book?.author ?? '', style: TextStyle(fontSize: 13, color: (dark ? Colors.white70 : Colors.black54))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: dueDateColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isOverdue ? Icons.warning_rounded : Icons.timer_rounded, color: dueDateColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              isOverdue ? 'Overdue' : (daysLeft == 0 ? 'Due Today' : '$daysLeft days left'),
                              style: TextStyle(color: dueDateColor, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _loading ? null : () => _action(
                      () => state.returnBook(borrow.id), 
                      'Returned Successfully! 📚', 
                      'Thank you for returning the book. Your contribution keeps LibHub running!', 
                      Icons.check_circle_rounded, 
                      AppTheme.successColor
                    ),
                    icon: const Icon(Icons.keyboard_return_rounded, size: 18),
                    label: const Text('Return', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (borrow.renewalCount < borrow.maxRenewals)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor]),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : () => _action(
                          () => state.renewBook(borrow.id), 
                          'Time Extended! 🔄', 
                          'Your reading time has been renewed. Enjoy the chapters ahead!', 
                          Icons.autorenew_rounded, 
                          AppTheme.primaryColor
                        ),
                        icon: _loading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.update_rounded, size: 18),
                        label: const Text('Renew', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text('Exceeded renewals', style: TextStyle(fontSize: 11, color: (dark ? Colors.white24 : Colors.black26), fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReserveCard extends StatefulWidget {
  final Reserve reserve;
  const _ReserveCard({required this.reserve});

  @override
  State<_ReserveCard> createState() => _ReserveCardState();
}

class _ReserveCardState extends State<_ReserveCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final reserve = widget.reserve;
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final dark = AppTheme.isDarkMode(context);
    final book = reserve.book;
    final isReady = reserve.status == 'ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isReady ? AppTheme.successColor.withOpacity(0.3) : (dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: book?.coverImage != null
                ? Image.network(book!.coverImage!, width: 60, height: 86, fit: BoxFit.cover)
                : Container(
                    width: 60, height: 86,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: const Icon(Icons.book, color: AppTheme.primaryColor, size: 28),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book?.title ?? 'Unknown Book', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.5), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                Text(book?.author ?? '', style: TextStyle(fontSize: 12, color: (dark ? Colors.white70 : Colors.black54))),
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isReady ? AppTheme.successColor : AppTheme.secondaryColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(isReady ? Icons.check_circle_rounded : Icons.person_pin_circle_rounded, size: 12, color: isReady ? AppTheme.successColor : AppTheme.secondaryColor),
                        const SizedBox(width: 6),
                        Text(
                          isReady ? 'READY TO BORROW' : 'QUEUE POSITION: #${reserve.queuePosition}',
                          style: TextStyle(
                            color: isReady ? AppTheme.successColor : AppTheme.secondaryColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5
                          )
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
          _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.errorColor))
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: AppTheme.errorColor, size: 18),
                  ),
                  onPressed: () async {
                    setState(() => _loading = true);
                    final result = await state.cancelReserve(reserve.id);
                    if (mounted) {
                      setState(() => _loading = false);
                      if (result['error'] != null) {
                        PremiumDialog.show(
                          context: context, 
                          title: 'Error', 
                          message: result['error'],
                          icon: Icons.error_outline_rounded,
                          iconColor: AppTheme.errorColor,
                        );
                      }
                    }
                  },
                ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDarkMode(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: AppTheme.primaryColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            Text(
              message, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)
            ),
            const SizedBox(height: 12),
            Text(
              sub, 
              style: TextStyle(fontSize: 15, color: (dark ? Colors.white70 : Colors.black54), height: 1.5), 
              textAlign: TextAlign.center
            ),
          ],
        ),
      ),
    );
  }
}
