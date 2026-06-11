import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/otp_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            // Profile Header
            SliverToBoxAdapter(child: _ProfileHeader()),
            // Sections
            SliverToBoxAdapter(child: _ReadingGoalsSection()),
            SliverToBoxAdapter(child: _NotificationPrefsSection()),
            SliverToBoxAdapter(child: _AccountSection()),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF7C3AED)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              profile != null && profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(profile?.fullName ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(profile?.email ?? '', style: const TextStyle(color: Color(0xFFE0E7FF), fontSize: 13)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _PillBadge(label: _tierLabel(profile?.membershipTier ?? 'free'), icon: Icons.workspace_premium_rounded),
            if (profile != null && !profile.emailVerified) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPScreen())),
                child: const _PillBadge(label: 'Verify Email', icon: Icons.warning_rounded, isWarning: true),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          // Dark mode toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Dark Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(width: 10),
              Switch(
                value: state.isDarkMode,
                onChanged: (_) => state.toggleDarkMode(),
                activeColor: AppTheme.secondaryColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'premium': return 'Premium Member';
      case 'vip': return 'VIP Member';
      default: return 'Free Member';
    }
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isWarning;
  const _PillBadge({required this.label, required this.icon, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isWarning ? AppTheme.warningColor.withOpacity(0.2) : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isWarning ? AppTheme.warningColor : Colors.white.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: isWarning ? AppTheme.warningColor : Colors.white),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: isWarning ? AppTheme.warningColor : Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ReadingGoalsSection extends StatefulWidget {
  @override
  State<_ReadingGoalsSection> createState() => _ReadingGoalsSectionState();
}

class _ReadingGoalsSectionState extends State<_ReadingGoalsSection> {
  bool _editing = false;
  late TextEditingController _yearlyCtrl;
  late TextEditingController _monthlyCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final goal = context.read<AppState>().readingGoal;
    _yearlyCtrl = TextEditingController(text: '${goal?.yearlyGoal ?? 12}');
    _monthlyCtrl = TextEditingController(text: '${goal?.monthlyGoal ?? 1}');
  }

  @override
  void dispose() {
    _yearlyCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goal = state.readingGoal;
    final theme = Theme.of(context);

    return _Section(
      title: 'Reading Goals',
      icon: Icons.track_changes_rounded,
      trailing: IconButton(
        icon: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded, size: 20),
        onPressed: () async {
          if (_editing) {
            final yearly = int.tryParse(_yearlyCtrl.text) ?? goal?.yearlyGoal ?? 12;
            final monthly = int.tryParse(_monthlyCtrl.text) ?? goal?.monthlyGoal ?? 1;
            await state.updateReadingGoal(yearly, monthly);
          }
          setState(() => _editing = !_editing);
        },
      ),
      child: goal == null
          ? const Text('No reading goals set')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalBar(
                  label: 'Yearly Goal (${DateTime.now().year})',
                  current: goal.booksReadYear,
                  target: _editing ? int.tryParse(_yearlyCtrl.text) ?? goal.yearlyGoal : goal.yearlyGoal,
                  progress: goal.yearlyProgress,
                  editCtrl: _editing ? _yearlyCtrl : null,
                ),
                const SizedBox(height: 16),
                _GoalBar(
                  label: 'Monthly Goal (this month)',
                  current: goal.booksReadMonth,
                  target: _editing ? int.tryParse(_monthlyCtrl.text) ?? goal.monthlyGoal : goal.monthlyGoal,
                  progress: goal.monthlyProgress,
                  editCtrl: _editing ? _monthlyCtrl : null,
                ),
              ],
            ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final double progress;
  final TextEditingController? editCtrl;
  const _GoalBar({required this.label, required this.current, required this.target, required this.progress, this.editCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        editCtrl != null
            ? SizedBox(
                width: 60,
                child: TextField(
                  controller: editCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                ),
              )
            : Text('$current / $target', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
      ]),
      const SizedBox(height: 8),
      LinearPercentIndicator(
        lineHeight: 8,
        percent: progress,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        progressColor: progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
        barRadius: const Radius.circular(4),
        padding: EdgeInsets.zero,
      ),
    ]);
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
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryColor),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return _Section(
      title: 'Account',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _MenuTile(icon: Icons.workspace_premium_rounded, label: 'Upgrade Membership', onTap: () {}),
          _MenuTile(icon: Icons.payment_rounded, label: 'Payment History', onTap: () {}),
          _MenuTile(icon: Icons.receipt_long_rounded, label: 'My Fines', onTap: () {}),
          _MenuTile(icon: Icons.verified_user_rounded, label: 'Verify Email', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPScreen()))),
          const Divider(height: 24),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor ?? theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.textTheme.bodyMedium?.color),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (trailing != null) ...[const Spacer(), trailing!],
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
