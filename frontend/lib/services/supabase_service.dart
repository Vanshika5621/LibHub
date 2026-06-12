import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../constants.dart';
import '../models/book.dart';
import '../models/profile.dart';
import '../models/borrow.dart';
import '../models/reserve.dart';
import '../models/goal.dart';
import '../models/notification.dart';
import '../models/chat_message.dart';
import '../models/fine.dart';
import '../models/payment.dart';

class SupabaseService {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;

  // Authentication Helpers
  sb.User? get currentUser => _client.auth.currentUser;
  sb.Session? get currentSession => _client.auth.currentSession;
  String? get accessToken => currentSession?.accessToken;

  // Header Helper
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  // Sign In
  Future<sb.AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Register via Backend Admin API (bypasses email confirmation requirement)
  Future<void> registerViaBackend({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.backendBaseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address,
        'city': city,
      }),
    );
    final result = json.decode(response.body);
    if (response.statusCode != 200 || result['success'] != true) {
      throw Exception(result['error'] ?? 'Registration failed. Please try again.');
    }
  }

  // OTP Sending (via Next.js backend API)
  Future<Map<String, dynamic>> sendOTP() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/otp/send'),
        headers: _headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // OTP Verification (via Next.js backend API)
  Future<Map<String, dynamic>> verifyOTP(String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/otp/verify'),
        headers: _headers,
        body: json.encode({'otp': otpCode}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Profile
  Future<Profile?> getProfile() async {
    if (currentUser == null) return null;
    final data = await _client.from('profiles').select().eq('id', currentUser!.id).single();
    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile(Map<String, dynamic> updates) async {
    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', currentUser!.id)
        .select()
        .single();
    return Profile.fromJson(data);
  }

  // Books
  Future<List<Book>> getBooks({
    String query = '',
    String genre = '',
    bool onlyAvailable = false,
    String sortBy = 'rating',
  }) async {
    try {
      // Build the query step by step
      var q = _client.from('books').select();

      if (genre.isNotEmpty && genre != 'All') {
        q = q.eq('genre', genre);
      }

      if (onlyAvailable) {
        q = q.gt('available_copies', 0);
      }

      // Apply sort - order() returns PostgrestTransformBuilder so we execute directly
      List<dynamic> response;
      if (sortBy == 'rating') {
        response = await q.order('rating', ascending: false);
      } else if (sortBy == 'new') {
        response = await q.order('is_new_arrival', ascending: false);
      } else {
        response = await q.order('created_at', ascending: false);
      }

      List<Book> books = response.map((x) => Book.fromJson(x as Map<String, dynamic>)).toList();

      // Client-side simple search filter
      if (query.isNotEmpty) {
        final cleanQuery = query.toLowerCase();
        books = books.where((b) {
          return b.title.toLowerCase().contains(cleanQuery) ||
              b.author.toLowerCase().contains(cleanQuery) ||
              (b.description != null && b.description!.toLowerCase().contains(cleanQuery));
        }).toList();
      }

      return books;
    } catch (e) {
      print('Supabase getBooks error, falling back to mock books: $e');
      return _getMockBooks(
        query: query,
        genre: genre,
        onlyAvailable: onlyAvailable,
        sortBy: sortBy,
      );
    }
  }

  Future<Book> getBookById(String bookId) async {
    try {
      final data = await _client.from('books').select().eq('id', bookId).single();
      return Book.fromJson(data);
    } catch (e) {
      print('Supabase getBookById error, looking in mock books: $e');
      final mocks = _getMockBooks();
      return mocks.firstWhere((b) => b.id == bookId, orElse: () => throw Exception('Book not found'));
    }
  }

  // Borrows
  Future<List<Borrow>> getUserBorrows() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('borrows')
        .select('*, books(*)')
        .eq('user_id', currentUser!.id)
        .order('borrowed_at', ascending: false);
    return response.map((x) => Borrow.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> borrowBook(String bookId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/books/borrow'),
        headers: _headers,
        body: json.encode({'bookId': bookId}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> returnBook(String borrowId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/books/return'),
        headers: _headers,
        body: json.encode({'borrowId': borrowId}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> renewBook(String borrowId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/books/renew'),
        headers: _headers,
        body: json.encode({'borrowId': borrowId}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Reserves
  Future<List<Reserve>> getUserReserves() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('reserves')
        .select('*, books(*)')
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return response.map((x) => Reserve.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> reserveBook(String bookId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/books/reserve'),
        headers: _headers,
        body: json.encode({'bookId': bookId}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelReserve(String reserveId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/books/cancel-reserve'),
        headers: _headers,
        body: json.encode({'reserveId': reserveId}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Wishlist
  Future<List<String>> getWishlistIds() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('wishlist')
        .select('book_id')
        .eq('user_id', currentUser!.id);
    return response.map((x) => x['book_id'] as String).toList();
  }

  Future<List<Book>> getWishlistBooks() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('wishlist')
        .select('*, books(*)')
        .eq('user_id', currentUser!.id);
    return response
        .where((x) => x['books'] != null)
        .map((x) => Book.fromJson(x['books'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToWishlist(String bookId) async {
    if (currentUser == null) return;
    await _client.from('wishlist').insert({
      'user_id': currentUser!.id,
      'book_id': bookId,
    });
  }

  Future<void> removeFromWishlist(String bookId) async {
    if (currentUser == null) return;
    await _client
        .from('wishlist')
        .delete()
        .eq('user_id', currentUser!.id)
        .eq('book_id', bookId);
  }

  // Fines
  Future<List<Fine>> getUserFines() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('fines')
        .select('*, borrows(*, books(*))')
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return response.map((x) => Fine.fromJson(x as Map<String, dynamic>)).toList();
  }

  // Payments History
  Future<List<Payment>> getUserPayments() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('payments')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return response.map((x) => Payment.fromJson(x as Map<String, dynamic>)).toList();
  }

  // Reading Goals
  Future<ReadingGoal?> getReadingGoal(int year) async {
    if (currentUser == null) return null;
    try {
      final data = await _client
          .from('reading_goals')
          .select()
          .eq('user_id', currentUser!.id)
          .eq('year', year)
          .single();
      return ReadingGoal.fromJson(data);
    } catch (_) {
      // In case goal for current year does not exist yet, let's create a default one
      final Map<String, dynamic> newGoal = {
        'user_id': currentUser!.id,
        'year': year,
        'yearly_goal': 12,
        'monthly_goal': 1,
        'books_read_year': 0,
        'books_read_month': 0,
        'current_month': DateTime.now().month,
      };
      final data = await _client.from('reading_goals').insert(newGoal).select().single();
      return ReadingGoal.fromJson(data);
    }
  }

  Future<ReadingGoal> updateReadingGoal(int year, int yearlyGoal, int monthlyGoal) async {
    final data = await _client
        .from('reading_goals')
        .update({
          'yearly_goal': yearlyGoal,
          'monthly_goal': monthlyGoal,
        })
        .eq('user_id', currentUser!.id)
        .eq('year', year)
        .select()
        .single();
    return ReadingGoal.fromJson(data);
  }

  // Notifications
  Future<List<NotificationModel>> getUserNotifications() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('notifications')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return response.map((x) => NotificationModel.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<NotificationPreferences?> getNotificationPreferences() async {
    if (currentUser == null) return null;
    final data = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', currentUser!.id)
        .single();
    return NotificationPreferences.fromJson(data);
  }

  Future<NotificationPreferences> updateNotificationPreferences(Map<String, dynamic> updates) async {
    final data = await _client
        .from('notification_preferences')
        .update(updates)
        .eq('user_id', currentUser!.id)
        .select()
        .single();
    return NotificationPreferences.fromJson(data);
  }

  // AI Chat Messages
  Future<List<ChatMessage>> getChatMessages() async {
    if (currentUser == null) return [];
    final List<dynamic> response = await _client
        .from('chat_messages')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: true);
    return response.map((x) => ChatMessage.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> saveChatMessage(String role, String content) async {
    final data = await _client.from('chat_messages').insert({
      'user_id': currentUser!.id,
      'role': role,
      'content': content,
    }).select().single();
    return ChatMessage.fromJson(data);
  }

  // AI recommendations / responses (via Next.js AI chat api endpoint)
  Future<Map<String, dynamic>> getAIResponse(String message) async {
    try {
      final response = await http
          .post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/ai/chat'),
        headers: _headers,
        body: json.encode({
          'messages': [
            {'role': 'user', 'content': message}
          ]
        }),
      )
          .timeout(const Duration(seconds: 20));
      return json.decode(response.body);
    } on TimeoutException catch (_) {
      return {'error': 'AI request timed out. Please try again.'};
    } on SocketException catch (_) {
      return {'error': 'Network error while contacting AI service.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  List<Book> _getMockBooks({
    String query = '',
    String genre = '',
    bool onlyAvailable = false,
    String sortBy = 'rating',
  }) {
    final List<Book> mockList = [
      Book(
        id: 'mock-1',
        title: 'The God of Small Things',
        author: 'Arundhati Roy',
        publisher: 'IndiaInk',
        description: 'A story of childhood experiences of fraternal twins whose lives are destroyed by societal laws.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/91iM5pE1ojL.jpg',
        genre: 'Fiction',
        language: 'English',
        pages: 340,
        publishedYear: 1997,
        isbn: '978-0060977493',
        totalCopies: 5,
        availableCopies: 5,
        rating: 4.5,
        ratingCount: 1200,
        isTrending: true,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Book(
        id: 'mock-2',
        title: 'Midnight\'s Children',
        author: 'Salman Rushdie',
        publisher: 'Jonathan Cape',
        description: 'The story of Saleem Sinai, born at the exact moment of India\'s independence.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/81WcnNQ-TBL.jpg',
        genre: 'Fiction',
        language: 'English',
        pages: 647,
        publishedYear: 1981,
        isbn: '978-0099511894',
        totalCopies: 4,
        availableCopies: 3,
        rating: 4.3,
        ratingCount: 980,
        isTrending: true,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
      ),
      Book(
        id: 'mock-3',
        title: 'The White Tiger',
        author: 'Aravind Adiga',
        publisher: 'Atlantic Books',
        description: 'A darkly humorous perspective of India\'s class struggle through a village boy\'s eyes.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/71FTb9X6wsL.jpg',
        genre: 'Fiction',
        language: 'English',
        pages: 321,
        publishedYear: 2008,
        isbn: '978-1416562603',
        totalCopies: 6,
        availableCopies: 6,
        rating: 4.1,
        ratingCount: 750,
        isTrending: true,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Book(
        id: 'mock-4',
        title: 'Atomic Habits',
        author: 'James Clear',
        publisher: 'Avery',
        description: 'An easy and proven way to build good habits and break bad ones.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/81wgFLlhSFL.jpg',
        genre: 'Self-Help',
        language: 'English',
        pages: 320,
        publishedYear: 2018,
        isbn: '978-0735211292',
        totalCopies: 8,
        availableCopies: 7,
        rating: 4.8,
        ratingCount: 5000,
        isTrending: true,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Book(
        id: 'mock-5',
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        publisher: 'Harper',
        description: 'A brief history of humankind from the Stone Age to the twenty-first century.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/713jIoNE3ML.jpg',
        genre: 'History',
        language: 'English',
        pages: 443,
        publishedYear: 2011,
        isbn: '978-0062316097',
        totalCopies: 5,
        availableCopies: 5,
        rating: 4.6,
        ratingCount: 4200,
        isTrending: true,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Book(
        id: 'mock-6',
        title: 'The Alchemist',
        author: 'Paulo Coelho',
        publisher: 'HarperOne',
        description: 'A shepherd boy travels from Spain to Egypt in search of treasure.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/71aFt4+otOL.jpg',
        genre: 'Fiction',
        language: 'English',
        pages: 208,
        publishedYear: 1988,
        isbn: '978-0062315007',
        totalCopies: 7,
        availableCopies: 6,
        rating: 4.4,
        ratingCount: 3800,
        isTrending: false,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Book(
        id: 'mock-7',
        title: 'Ikigai',
        author: 'Héctor García',
        publisher: 'Penguin',
        description: 'The Japanese secret to a long and happy life.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/71T4C8uI5BL.jpg',
        genre: 'Self-Help',
        language: 'English',
        pages: 208,
        publishedYear: 2016,
        isbn: '978-1523504721',
        totalCopies: 4,
        availableCopies: 4,
        rating: 4.2,
        ratingCount: 2100,
        isTrending: false,
        isNewArrival: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Book(
        id: 'mock-8',
        title: 'The Psychology of Money',
        author: 'Morgan Housel',
        publisher: 'Harriman House',
        description: 'Timeless lessons on wealth, greed, and happiness.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/71g2ednj0JL.jpg',
        genre: 'Business',
        language: 'English',
        pages: 256,
        publishedYear: 2020,
        isbn: '978-0857197689',
        totalCopies: 5,
        availableCopies: 5,
        rating: 4.7,
        ratingCount: 3200,
        isTrending: false,
        isNewArrival: true,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Book(
        id: 'mock-9',
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        publisher: 'Ballantine Books',
        description: 'A lone astronaut must save humanity from extinction.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/81m1qm4F0aL.jpg',
        genre: 'Technology',
        language: 'English',
        pages: 496,
        publishedYear: 2021,
        isbn: '978-0593135204',
        totalCopies: 3,
        availableCopies: 2,
        rating: 4.6,
        ratingCount: 2800,
        isTrending: false,
        isNewArrival: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Book(
        id: 'mock-10',
        title: 'The Palace of Illusions',
        author: 'Chitra Banerjee Divakaruni',
        publisher: 'Picador',
        description: 'The Mahabharata retold from Draupadi\'s perspective.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/81Y7P7YpQSL.jpg',
        genre: 'History',
        language: 'English',
        pages: 360,
        publishedYear: 2008,
        isbn: '978-0330458535',
        totalCopies: 4,
        availableCopies: 4,
        rating: 4.4,
        ratingCount: 1500,
        isTrending: false,
        isNewArrival: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Book(
        id: 'mock-11',
        title: 'Rich Dad Poor Dad',
        author: 'Robert Kiyosaki',
        publisher: 'Plata Publishing',
        description: 'What the rich teach their kids about money that the poor do not.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/81bsw6fnUiL.jpg',
        genre: 'Business',
        language: 'English',
        pages: 336,
        publishedYear: 1997,
        isbn: '978-1612680194',
        totalCopies: 6,
        availableCopies: 5,
        rating: 4.3,
        ratingCount: 4500,
        isTrending: false,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Book(
        id: 'mock-12',
        title: 'The Immortals of Meluha',
        author: 'Amish Tripathi',
        publisher: 'Westland',
        description: 'The first book of the Shiva Trilogy.',
        coverImage: 'https://images-na.ssl-images-amazon.com/images/I/71jQapTNjUL.jpg',
        genre: 'History',
        language: 'English',
        pages: 412,
        publishedYear: 2010,
        isbn: '978-9380658747',
        totalCopies: 5,
        availableCopies: 4,
        rating: 4.2,
        ratingCount: 2200,
        isTrending: true,
        isNewArrival: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    Iterable<Book> filtered = mockList;

    if (genre.isNotEmpty && genre != 'All') {
      filtered = filtered.where((b) => b.genre.toLowerCase() == genre.toLowerCase());
    }

    if (onlyAvailable) {
      filtered = filtered.where((b) => b.availableCopies > 0);
    }

    if (query.isNotEmpty) {
      final cleanQuery = query.toLowerCase();
      filtered = filtered.where((b) {
        return b.title.toLowerCase().contains(cleanQuery) ||
            b.author.toLowerCase().contains(cleanQuery) ||
            (b.description != null && b.description!.toLowerCase().contains(cleanQuery));
      });
    }

    List<Book> result = filtered.toList();

    if (sortBy == 'rating') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sortBy == 'new') {
      result.sort((a, b) => (b.isNewArrival ? 1 : 0).compareTo(a.isNewArrival ? 1 : 0));
    } else {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }
}
