import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/profile.dart';
import '../models/borrow.dart';
import '../models/reserve.dart';
import '../models/fine.dart';
import '../models/notification.dart';

class CacheService {
  static const String _keyProfile = 'cache_profile';
  static const String _keyBooks = 'cache_books';
  static const String _keyBorrows = 'cache_borrows';
  static const String _keyReserves = 'cache_reserves';
  static const String _keyFines = 'cache_fines';
  static const String _keyNotifications = 'cache_notifications';
  static const String _keyDarkMode = 'cache_dark_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic Save
  static Future<void> _save(String key, dynamic data) async {
    if (_prefs == null) await init();
    if (data == null) {
      await _prefs!.remove(key);
    } else {
      await _prefs!.setString(key, json.encode(data));
    }
  }

  // Generic Get
  static dynamic _get(String key) {
    if (_prefs == null) return null;
    final String? val = _prefs!.getString(key);
    if (val == null) return null;
    try {
      return json.decode(val);
    } catch (_) {
      return null;
    }
  }

  // Profile
  static Future<void> saveProfile(Profile? profile) => _save(_keyProfile, profile?.toJson());
  static Profile? getProfile() {
    final data = _get(_keyProfile);
    return data != null ? Profile.fromJson(data) : null;
  }

  // Books
  static Future<void> saveBooks(List<Book> books) => _save(_keyBooks, books.map((e) => e.toJson()).toList());
  static List<Book> getBooks() {
    final data = _get(_keyBooks);
    if (data is List) {
      return data.map((e) => Book.fromJson(e)).toList();
    }
    return [];
  }

  // Borrows
  static Future<void> saveBorrows(List<Borrow> borrows) => _save(_keyBorrows, borrows.map((e) => e.toJson()).toList());
  static List<Borrow> getBorrows() {
    final data = _get(_keyBorrows);
    if (data is List) {
      return data.map((e) => Borrow.fromJson(e)).toList();
    }
    return [];
  }

  // Reserves
  static Future<void> saveReserves(List<Reserve> reserves) => _save(_keyReserves, reserves.map((e) => e.toJson()).toList());
  static List<Reserve> getReserves() {
    final data = _get(_keyReserves);
    if (data is List) {
      return data.map((e) => Reserve.fromJson(e)).toList();
    }
    return [];
  }

  // Fines
  static Future<void> saveFines(List<Fine> fines) => _save(_keyFines, fines.map((e) => e.toJson()).toList());
  static List<Fine> getFines() {
    final data = _get(_keyFines);
    if (data is List) {
      return data.map((e) => Fine.fromJson(e)).toList();
    }
    return [];
  }

  // Notifications
  static Future<void> saveNotifications(List<NotificationModel> notifications) => _save(_keyNotifications, notifications.map((e) => e.toJson()).toList());
  static List<NotificationModel> getNotifications() {
    final data = _get(_keyNotifications);
    if (data is List) {
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }
    return [];
  }

  // Dark Mode
  static Future<void> saveDarkMode(bool isDark) async {
    if (_prefs == null) await init();
    await _prefs!.setBool(_keyDarkMode, isDark);
  }
  static bool getDarkMode() {
    return _prefs?.getBool(_keyDarkMode) ?? false;
  }

  // Clear all cache
  static Future<void> clearAuthCache() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_keyProfile);
    await _prefs!.remove(_keyBorrows);
    await _prefs!.remove(_keyReserves);
    await _prefs!.remove(_keyFines);
    await _prefs!.remove(_keyNotifications);
  }
}
