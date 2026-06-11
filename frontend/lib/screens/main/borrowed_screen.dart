import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/borrow.dart';
import '../../models/reserve.dart';

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
                ? _EmptyState(icon: Icons.library_books_outlined, message: 'No active borrows', sub: 'Head to the catalog to borrow books')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeBorrows.length,
                    itemBuilder: (ctx, i) => _BorrowCard(borrow: activeBorrows[i]),
                  ),
            // Reserves Tab
            reserves.isEmpty
                ? _EmptyState(icon: Icons.bookmark_outline_rounded, message: 'No active reserves', sub: 'Reserve an unavailable book from its detail page')
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

  Future<void> _action(Future<Map<String, dynamic>> Function() action, String successMsg) async {
    setState(() => _loading = true);
    final result = await action();
    if (mounted) {
      setState(() => _loading = false);
      final ok = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? successMsg : (result['error'] ?? 'Error')),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrow = widget.borrow;
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final dueDate = borrow.dueDate;
    final now = DateTime.now();
    final daysLeft = dueDate.difference(now).inDays;
    final isOverdue = borrow.isOverdue;
    final dueDateColor = isOverdue ? AppTheme.errorColor : (daysLeft <= 3 ? AppTheme.warningColor : AppTheme.successColor);

    final book = borrow.book;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOverdue ? AppTheme.errorColor.withOpacity(0.4) : theme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: book?.coverImage != null
                      ? Image.network(book!.coverImage!, width: 56, height: 76, fit: BoxFit.cover)
                      : Container(
                          width: 56, height: 76,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          alignment: Alignment.center,
                          child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book?.title ?? 'Unknown Book', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(book?.author ?? '', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(isOverdue ? Icons.warning_rounded : Icons.schedule_rounded, color: dueDateColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue ? 'Overdue by ${now.difference(dueDate).inDays} days' : (daysLeft == 0 ? 'Due today!' : 'Due in $daysLeft day${daysLeft == 1 ? '' : 's'}'),
                          style: TextStyle(color: dueDateColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text('Due: ${DateFormat('dd MMM yyyy').format(dueDate)}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('Renewals: ${borrow.renewalCount}/${borrow.maxRenewals}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(padding: EdgeInsets.only(bottom: 12), child: CircularProgressIndicator(color: AppTheme.primaryColor))
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _action(() => state.returnBook(borrow.id), '📚 Book returned!'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), side: const BorderSide(color: AppTheme.primaryColor)),
                      child: const Text('Return', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  if (borrow.renewalCount < borrow.maxRenewals) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _action(() => state.renewBook(borrow.id), '🔄 Renewed successfully!'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('Renew', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
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
    final book = reserve.book;
    final isReady = reserve.status == 'ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReady ? AppTheme.successColor.withOpacity(0.4) : theme.dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: book?.coverImage != null
                ? Image.network(book!.coverImage!, width: 50, height: 68, fit: BoxFit.cover)
                : Container(
                    width: 50, height: 68,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book?.title ?? 'Unknown Book', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(book?.author ?? '', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isReady ? AppTheme.successColor : AppTheme.secondaryColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isReady ? 'Ready to Borrow' : 'Queue #${reserve.queuePosition}',
                        style: TextStyle(color: isReady ? AppTheme.successColor : AppTheme.secondaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
                if (reserve.estimatedDate != null) ...[
                  const SizedBox(height: 4),
                  Text('Est: ${DateFormat('dd MMM').format(reserve.estimatedDate!)}', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                ],
              ],
            ),
          ),
          _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.errorColor))
              : IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.errorColor, size: 22),
                  onPressed: () async {
                    setState(() => _loading = true);
                    final result = await state.cancelReserve(reserve.id);
                    if (mounted) {
                      setState(() => _loading = false);
                      if (result['error'] != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: AppTheme.errorColor));
                      }
                    }
                  },
                  tooltip: 'Cancel Reserve',
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
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 72, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(sub, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
      ]),
    );
  }
}
