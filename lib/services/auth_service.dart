import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static const String _keyUser = 'pref_portal_user';
  static const String _keyToken = 'pref_portal_token';

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Initialize auth state from local storage on app start
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyUser);
      _token = prefs.getString(_keyToken);

      if (userJson != null) {
        final Map<String, dynamic> map = jsonDecode(userJson);
        _currentUser = UserModel.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) print('AuthService init error: $e');
    }
    notifyListeners();
  }

  /// Perform login against backend API
  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
    String role = 'all',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.login(
        email: email,
        password: password,
        role: role,
      );

      if (res.success && res.data != null) {
        final userData = res.data!['user'] as Map<String, dynamic>;
        _token = res.data!['token']?.toString();
        _currentUser = UserModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));
        if (_token != null) {
          await prefs.setString(_keyToken, _token!);
        }

        _isLoading = false;
        notifyListeners();

        return ApiResponse(
          success: true,
          message: res.message,
          data: _currentUser,
          statusCode: res.statusCode,
        );
      } else {
        _isLoading = false;
        notifyListeners();
        return ApiResponse(
          success: false,
          message: res.message,
          statusCode: res.statusCode,
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse(
        success: false,
        message: 'Login failed: $e',
        statusCode: 0,
      );
    }
  }

  /// Logout and clear stored session
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      await prefs.remove(_keyToken);
    } catch (e) {
      if (kDebugMode) print('Logout error: $e');
    }
    notifyListeners();
  }
}
