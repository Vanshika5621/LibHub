import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/otp_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showUpgradePlans(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Membership Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _UpgradePlanOption(
                name: 'Premium Plan',
                price: 299,
                tier: 'premium',
                features: 'Up to 5 books at a time, 21-day borrow period, priority book reservation.',
                isCurrent: state.profile?.membershipTier == 'premium',
                onTap: () {
                  Navigator.pop(context);
                  state.upgradeMembership('premium', 299, context);
                },
              ),
              const SizedBox(height: 12),
              _UpgradePlanOption(
                name: 'VIP Plan',
                price: 599,
                tier: 'vip',
                features: 'Unlimited books, 30-day borrow period, 2 fine waivers per month, personalized AI recommendations.',
                isCurrent: state.profile?.membershipTier == 'vip',
                onTap: () {
                  Navigator.pop(context);
                  state.upgradeMembership('vip', 599, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentHistory(BuildContext context) {
    final state = context.read<AppState>();
    final payments = state.payments;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: payments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('No transactions found.'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(p.createdAt);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              p.paymentType == 'membership' ? Icons.workspace_premium_rounded : Icons.receipt_long_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.paymentType == 'membership'
                                        ? '${p.membershipTier?.toUpperCase() ?? "PLAN"} Plan Upgrade'
                                        : 'Late Fine Payment',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$dateStr\nStatus: ${p.status.toUpperCase()}',
                                    style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${p.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFines(BuildContext context) {
    final state = context.read<AppState>();
    final fines = state.fines;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('My Fines', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: fines.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('No fines recorded. You are all clear! 🎉'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: fines.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final fine = fines[index];
                      final isUnpaid = !fine.paid && !fine.waived;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fine.borrow?.book?.title ?? 'Library Book Fine',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${fine.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isUnpaid ? AppTheme.errorColor : AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Overdue fine: ${fine.daysOverdue} days late',
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (fine.paid ? AppTheme.successColor : (fine.waived ? Colors.grey : AppTheme.errorColor)).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    fine.paid ? 'PAID' : (fine.waived ? 'WAIVED' : 'UNPAID'),
                                    style: TextStyle(
                                      color: fine.paid ? AppTheme.successColor : (fine.waived ? Colors.grey : AppTheme.errorColor),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (isUnpaid)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      state.payFine(fine.id, fine.amount, context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Pay Now', style: TextStyle(fontSize: 11)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_outline_rounded, size: 72, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text('Sign in to view your profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign In'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => state.loadUserData(),
        child: CustomScrollView(
          slivers: [
            // Profile Header / Card
            SliverToBoxAdapter(child: _ProfileHeader()),
            // Reading Goal progress and editor
            SliverToBoxAdapter(child: _ReadingGoalsSection()),
            // Notifications preferences
            SliverToBoxAdapter(child: _NotificationPrefsSection()),
            // Account utilities
            SliverToBoxAdapter(
              child: _AccountSection(
                onUpgradePress: () => _showUpgradePlans(context),
                onPaymentHistoryPress: () => _showPaymentHistory(context),
                onFinesPress: () => _showFines(context),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      ),
      child: Column(
        children: [
          // Digital Membership Library Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
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
                    const Icon(Icons.library_books_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'LIBHUB DIGITAL LIBRARY',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (profile?.membershipTier ?? 'free').toUpperCase(),
                        style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  profile?.fullName.toUpperCase() ?? 'READER NAME',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEMBER ID',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.id.substring(0, 13).toUpperCase() ?? 'LH-12345-ABCD',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                    const Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 36),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dark Mode quick row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: state.isDarkMode ? AppTheme.primaryColor : Colors.orange,
                ),
                onPressed: () => state.toggleDarkMode(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadingGoalsSection extends StatefulWidget {
  @override
  State<_ReadingGoalsSection> createState() => _ReadingGoalsSectionState();
}

class _ReadingGoalsSectionState extends State<_ReadingGoalsSection> {
  bool _editing = false;
  int _yearlyGoal = 12;
  int _monthlyGoal = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final goal = context.read<AppState>().readingGoal;
    if (goal != null && !_editing) {
      _yearlyGoal = goal.yearlyGoal;
      _monthlyGoal = goal.monthlyGoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goal = state.readingGoal;

    return _Section(
      title: 'Reading Goals',
      icon: Icons.track_changes_rounded,
      trailing: IconButton(
        icon: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded, size: 20),
        onPressed: () async {
          if (_editing) {
            await state.updateReadingGoal(_yearlyGoal, _monthlyGoal);
          }
          setState(() => _editing = !_editing);
        },
      ),
      child: goal == null
          ? const Text('No reading goals set')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalItem(
                  label: 'Yearly Goal (${DateTime.now().year})',
                  current: goal.booksReadYear,
                  target: _yearlyGoal,
                  progress: goal.yearlyProgress,
                  editing: _editing,
                  onChanged: (val) {
                    setState(() => _yearlyGoal = val);
                  },
                ),
                const SizedBox(height: 16),
                _GoalItem(
                  label: 'Monthly Goal (this month)',
                  current: goal.booksReadMonth,
                  target: _monthlyGoal,
                  progress: goal.monthlyProgress,
                  editing: _editing,
                  onChanged: (val) {
                    setState(() => _monthlyGoal = val);
                  },
                ),
              ],
            ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final double progress;
  final bool editing;
  final ValueChanged<int> onChanged;

  const _GoalItem({
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
    required this.editing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            if (editing)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.primaryColor, size: 20),
                    onPressed: target > 1 ? () => onChanged(target - 1) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('$target', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor, size: 20),
                    onPressed: () => onChanged(target + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              Text('$current / $target', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8,
          percent: progress.clamp(0.0, 1.0),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          progressColor: progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _NotificationPrefsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final prefs = state.notificationPrefs;

    return _Section(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      child: prefs == null
          ? const Text('Loading...')
          : Column(
              children: [
                _PrefToggle(label: 'Due Date Alerts', value: prefs.dueAlerts, onChanged: (v) => state.updateNotificationPrefs({'due_alerts': v})),
                _PrefToggle(label: 'Reserve Alerts', value: prefs.reserveAlerts, onChanged: (v) => state.updateNotificationPrefs({'reserve_alerts': v})),
                _PrefToggle(label: 'Payment Alerts', value: prefs.paymentAlerts, onChanged: (v) => state.updateNotificationPrefs({'payment_alerts': v})),
                _PrefToggle(label: 'System Alerts', value: prefs.systemAlerts, onChanged: (v) => state.updateNotificationPrefs({'system_alerts': v})),
              ],
            ),
    );
  }
}

class _PrefToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrefToggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryColor),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final VoidCallback onUpgradePress;
  final VoidCallback onPaymentHistoryPress;
  final VoidCallback onFinesPress;

  const _AccountSection({
    required this.onUpgradePress,
    required this.onPaymentHistoryPress,
    required this.onFinesPress,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return _Section(
      title: 'Account Settings',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.edit_rounded,
            label: 'Edit Profile Details',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const SizedBox(height: 6),
          _MenuTile(
            icon: Icons.workspace_premium_rounded,
            label: 'Upgrade Membership Plan',
            onTap: onUpgradePress,
          ),
          _MenuTile(
            icon: Icons.payment_rounded,
            label: 'Transaction History',
            onTap: onPaymentHistoryPress,
          ),
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            label: 'Late Fines & Penalties',
            onTap: onFinesPress,
          ),
          if (state.profile != null && !state.profile!.emailVerified)
            _MenuTile(
              icon: Icons.verified_user_rounded,
              label: 'Verify Email OTP',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPScreen())),
            ),
          const Divider(height: 24),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out Account',
            labelColor: AppTheme.errorColor,
            iconColor: AppTheme.errorColor,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorColor))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AppState>().signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.labelColor, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor ?? theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (trailing != null) ...[const Spacer(), trailing!],
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _UpgradePlanOption extends StatelessWidget {
  final String name;
  final int price;
  final String tier;
  final String features;
  final bool isCurrent;
  final VoidCallback onTap;

  const _UpgradePlanOption({
    required this.name,
    required this.price,
    required this.tier,
    required this.features,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primaryColor.withOpacity(0.04) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryColor.withOpacity(0.4) : theme.dividerColor,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '₹$price/mo',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            features,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.transparent)),
                    child: const Text('Active Plan'),
                  )
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: Text('Upgrade to ${tier.toUpperCase()}'),
                  ),
          ),
        ],
      ),
    );
  }
}
