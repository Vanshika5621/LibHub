import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/book.dart';
import '../models/profile.dart';
import '../models/borrow.dart';
import '../models/reserve.dart';
import '../models/goal.dart';
import '../models/notification.dart';
import '../models/chat_message.dart';
import '../models/fine.dart';
import '../models/payment.dart';
import '../services/supabase_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  SupabaseService get service => _service;

  AppState() {
    // Load public books immediately so guests see catalog without signing in
    reloadBooks();
  }

  // Auth
  bool get isLoggedIn => _service.currentUser != null;
  sb.User? get currentUser => _service.currentUser;

  // State
  Profile? _profile;
  List<Book> _books = [];
  List<Borrow> _borrows = [];
  List<Reserve> _reserves = [];
  List<String> _wishlistIds = [];
  List<Fine> _fines = [];
  List<Payment> _payments = [];
  ReadingGoal? _readingGoal;
  List<NotificationModel> _notifications = [];
  NotificationPreferences? _notificationPrefs;
  List<ChatMessage> _chatMessages = [];
  bool _isDarkMode = false;
  bool _isLoading = false;
  String? _error;
  int _currentTabIndex = 0;
  String _catalogSearchQuery = '';

  // Getters
  Profile? get profile => _profile;
  List<Book> get books => _books;
  List<Borrow> get borrows => _borrows;
  List<Reserve> get reserves => _reserves;
  List<String> get wishlistIds => _wishlistIds;
  List<Fine> get fines => _fines;
  List<Payment> get payments => _payments;
  ReadingGoal? get readingGoal => _readingGoal;
  List<NotificationModel> get notifications => _notifications;
  NotificationPreferences? get notificationPrefs => _notificationPrefs;
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentTabIndex => _currentTabIndex;
  String get catalogSearchQuery => _catalogSearchQuery;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void searchFromDashboard(String query) {
    _catalogSearchQuery = query;
    _currentTabIndex = 1; // Books Catalog Tab
    notifyListeners();
    reloadBooks(query: query);
  }

  void setCatalogSearchQuery(String query) {
    _catalogSearchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    _catalogSearchQuery = '';
    notifyListeners();
    reloadBooks(query: '');
  }

  int get activeBorrowsCount => _borrows.where((b) => b.status == 'active').length;
  int get activeReservesCount => _reserves.where((r) => r.status == 'waiting' || r.status == 'ready').length;
  int get unpaidFinesCount => _fines.where((f) => !f.paid && !f.waived).length;
  int get unreadNotificationsCount => _notifications.where((n) => !n.read).length;
  List<Book> get trendingBooks => _books.where((b) => b.isTrending).take(6).toList();
  List<Book> get newArrivals => _books.where((b) => b.isNewArrival).take(6).toList();

  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Load initial data after login (Optimized for speed)
  Future<void> loadUserData() async {
    if (!isLoggedIn) return;
    print('🚀 AppState: loading user data for ${currentUser?.email}');
    setLoading(true);
    setError(null);
    try {
      // 1. Get Profile FIRST (Essential)
      _profile = await _service.getProfile();
      
      if (_profile == null && currentUser != null) {
        print('⚠️ Profile missing! Attempting Auto-Fix with direct Insert...');
        final meta = currentUser!.userMetadata ?? {};
        // Use a direct insert through Supabase client to ensure it's created
        await _service.createProfileDirectly({
          'id': currentUser!.id,
          'email': currentUser!.email,
          'first_name': meta['first_name'] ?? 'Library',
          'last_name': meta['last_name'] ?? 'User',
          'phone': meta['phone'] ?? '',
          'address': meta['address'] ?? '',
          'city': meta['city'] ?? '',
          'email_verified': true,
        });
        _profile = await _service.getProfile();
      }

      if (_profile == null) {
        throw Exception('We logged you in, but could not create your library profile. Please check your internet or Supabase permissions.');
      }

      notifyListeners();

      // 2. Load EVERYTHING ELSE in parallel, but don't block the UI if one fails
      Future.wait([
        _service.getBooks().then((v) => _books = v),
        _service.getUserBorrows().then((v) => _borrows = v),
        _service.getUserReserves().then((v) => _reserves = v),
        _service.getWishlistIds().then((v) => _wishlistIds = v),
        _service.getUserFines().then((v) => _fines = v),
        _service.getUserPayments().then((v) => _payments = v),
        _service.getReadingGoal(DateTime.now().year).then((v) => _readingGoal = v),
        _service.getUserNotifications().then((v) => _notifications = v),
        _service.getNotificationPreferences().then((v) => _notificationPrefs = v),
        _service.getChatMessages().then((v) => _chatMessages = v),
      ]).then((_) {
        print('✅ AppState: All secondary data loaded');
        notifyListeners();
      }).catchError((e) {
        print('⚠️ Background load error: $e');
      });

    } catch (e) {
      print('❌ AppState Load Error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Load only books (for catalog refresh)
  Future<void> reloadBooks({
    String query = '',
    String genre = '',
    bool onlyAvailable = false,
    String sortBy = 'rating',
  }) async {
    print('📦 AppState: reloadBooks started for genre: $genre');
    setLoading(true);
    setError(null);
    try {
      _books = await _service.getBooks(
        query: query,
        genre: genre,
        onlyAvailable: onlyAvailable,
        sortBy: sortBy,
      );
      print('📚 AppState: ${ _books.length} books loaded successfully');
      notifyListeners();
    } catch (e) {
      print('❌ AppState Error loading books: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Refresh borrows
  Future<void> reloadBorrows() async {
    try {
      _borrows = await _service.getUserBorrows();
      notifyListeners();
    } catch (_) {}
  }

  // Refresh reserves
  Future<void> reloadReserves() async {
    try {
      _reserves = await _service.getUserReserves();
      notifyListeners();
    } catch (_) {}
  }

  // Refresh fines
  Future<void> reloadFines() async {
    try {
      _fines = await _service.getUserFines();
      notifyListeners();
    } catch (_) {}
  }

  // Toggle Wishlist
  Future<void> toggleWishlist(String bookId) async {
    final isWishlisted = _wishlistIds.contains(bookId);
    if (isWishlisted) {
      _wishlistIds.remove(bookId);
      notifyListeners();
      await _service.removeFromWishlist(bookId);
    } else {
      _wishlistIds.add(bookId);
      notifyListeners();
      await _service.addToWishlist(bookId);
    }
  }

  // Borrow
  Future<Map<String, dynamic>> borrowBook(String bookId) async {
    final result = await _service.borrowBook(bookId);
    if (result['success'] == true) {
      await reloadBorrows();
      // Update available copies locally
      final idx = _books.indexWhere((b) => b.id == bookId);
      if (idx >= 0) {
        final book = _books[idx];
        _books[idx] = Book(
          id: book.id, title: book.title, author: book.author,
          publisher: book.publisher, description: book.description,
          coverImage: book.coverImage, genre: book.genre,
          language: book.language, pages: book.pages,
          publishedYear: book.publishedYear, isbn: book.isbn,
          totalCopies: book.totalCopies,
          availableCopies: book.availableCopies - 1,
          rating: book.rating, ratingCount: book.ratingCount,
          isTrending: book.isTrending, isNewArrival: book.isNewArrival,
          createdAt: book.createdAt,
        );
        notifyListeners();
      }
    }
    return result;
  }

  // Return
  Future<Map<String, dynamic>> returnBook(String borrowId) async {
    final result = await _service.returnBook(borrowId);
    if (result['success'] == true) {
      await reloadBorrows();
      await reloadFines();
    }
    return result;
  }

  // Renew
  Future<Map<String, dynamic>> renewBook(String borrowId) async {
    final result = await _service.renewBook(borrowId);
    if (result['success'] == true) await reloadBorrows();
    return result;
  }

  // Reserve
  Future<Map<String, dynamic>> reserveBook(String bookId) async {
    final result = await _service.reserveBook(bookId);
    if (result['success'] == true) await reloadReserves();
    return result;
  }

  // Cancel Reserve
  Future<Map<String, dynamic>> cancelReserve(String reserveId) async {
    final result = await _service.cancelReserve(reserveId);
    if (result['success'] == true) await reloadReserves();
    return result;
  }

  // Mark notification as read
  Future<void> markNotificationRead(String id) async {
    await _service.markNotificationAsRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      final n = _notifications[idx];
      _notifications[idx] = NotificationModel(
        id: n.id, userId: n.userId, type: n.type,
        title: n.title, message: n.message,
        read: true, metadata: n.metadata, createdAt: n.createdAt,
      );
      notifyListeners();
    }
  }

  // Update Notification Preferences
  Future<void> updateNotificationPrefs(Map<String, dynamic> updates) async {
    final prefs = await _service.updateNotificationPreferences(updates);
    _notificationPrefs = prefs;
    notifyListeners();
  }

  // Send AI message
  Future<void> sendChatMessage(String content) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser?.id ?? '',
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    _chatMessages.add(userMsg);
    notifyListeners();

    // Save user message to Supabase
    if (isLoggedIn) {
      await _service.saveChatMessage('user', content);
    }

    // Get AI response from backend
    final result = await _service.getAIResponse(content);
    String? aiContent;
    if (result['message'] is Map) {
      aiContent = result['message']['content'] as String?;
    } else if (result['message'] is String) {
      aiContent = result['message'] as String;
    }
    aiContent ??= result['reply'] as String? ??
        result['error'] as String? ??
        'I\'m sorry, I couldn\'t process your request right now.';

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      userId: 'assistant',
      role: 'assistant',
      content: aiContent,
      createdAt: DateTime.now(),
    );
    _chatMessages.add(aiMsg);

    if (isLoggedIn) {
      await _service.saveChatMessage('assistant', aiContent);
    }

    notifyListeners();
  }

  // Upgrade membership using Razorpay
  Future<void> upgradeMembership(String tier, double amount, BuildContext context) async {
    if (!isLoggedIn || _profile == null) return;

    final paymentService = PaymentService(_service);
    paymentService.onSuccess = (response) async {
      // Show local loading or status
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verifying payment... Please wait.'),
        duration: Duration(seconds: 2),
      ));
      
      final verifyResult = await paymentService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        internalPaymentId: '',
      );

      if (verifyResult['success'] == true) {
        await loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan successfully upgraded to ${tier.toUpperCase()}! 🚀'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(verifyResult['error'] ?? 'Payment verification failed'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
      paymentService.dispose();
    };

    paymentService.onFailure = (response) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      paymentService.dispose();
    };

    final result = await paymentService.openCheckout(
      amount: amount,
      paymentType: 'membership',
      membershipTier: tier,
      userName: _profile!.fullName,
      userEmail: _profile!.email,
      userPhone: _profile!.phone ?? '9999999999',
    );

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error'] ?? 'Failed to open payment gateway'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Pay fine using Razorpay
  Future<void> payFine(String fineId, double amount, BuildContext context) async {
    if (!isLoggedIn || _profile == null) return;

    final paymentService = PaymentService(_service);
    paymentService.onSuccess = (response) async {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verifying fine payment... Please wait.'),
        duration: Duration(seconds: 2),
      ));

      final verifyResult = await paymentService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        internalPaymentId: '',
      );

      if (verifyResult['success'] == true) {
        await loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fine paid successfully! 💰'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(verifyResult['error'] ?? 'Verification failed'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
      paymentService.dispose();
    };

    paymentService.onFailure = (response) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      paymentService.dispose();
    };

    final result = await paymentService.openCheckout(
      amount: amount,
      paymentType: 'fine',
      fineId: fineId,
      userName: _profile!.fullName,
      userEmail: _profile!.email,
      userPhone: _profile!.phone ?? '9999999999',
    );

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error'] ?? 'Failed to open payment gateway'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Update Reading Goal
  Future<void> updateReadingGoal(int yearlyGoal, int monthlyGoal) async {
    if (_readingGoal == null) return;
    _readingGoal = await _service.updateReadingGoal(
      DateTime.now().year, yearlyGoal, monthlyGoal,
    );
    notifyListeners();
  }

  // Update Profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _profile = await _service.updateProfile(updates);
    notifyListeners();
  }

  // Sign Out
  Future<void> signOut() async {
    await _service.signOut();
    _profile = null;
    _books = [];
    _borrows = [];
    _reserves = [];
    _wishlistIds = [];
    _fines = [];
    _payments = [];
    _readingGoal = null;
    _notifications = [];
    _notificationPrefs = null;
    _chatMessages = [];
    notifyListeners();
  }
}
