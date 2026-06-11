import 'dart:convert';
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

  // Sign Up
  Future<sb.AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String city,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'address': address,
        'city': city,
      },
    );
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
  }

  Future<Book> getBookById(String bookId) async {
    final data = await _client.from('books').select().eq('id', bookId).single();
    return Book.fromJson(data);
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
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/ai/chat'),
        headers: _headers,
        body: json.encode({
          'messages': [
            {'role': 'user', 'content': message}
          ]
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
