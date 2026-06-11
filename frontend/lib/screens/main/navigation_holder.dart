import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/otp_screen.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'borrowed_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';

class NavigationHolder extends StatefulWidget {
  const NavigationHolder({super.key});

  @override
  State<NavigationHolder> createState() => _NavigationHolderState();
}

class _NavigationHolderState extends State<NavigationHolder> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CatalogScreen(),
    BorrowedScreen(),
    AIChatScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEmailVerification();
    });
  }

  void _checkEmailVerification() {
    final profile = context.read<AppState>().profile;
    if (profile != null && !profile.emailVerified) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OTPScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final unread = state.unreadNotificationsCount;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          )),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book_rounded), label: 'Books'),
            const BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books_rounded), label: 'Borrowed'),
            const BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy_rounded), label: 'AI'),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.person_outlined),
                  if (unread > 0)
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
