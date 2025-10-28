import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthViewModel() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final accessToken = await _storage.getAccessToken();
    final userData = await _storage.getUser();

    if (accessToken != null && userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      _api.setToken(accessToken);
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(username, password);

      final accessToken = response['access'];
      final refreshToken = response['refresh'];

      if (accessToken != null && refreshToken != null) {
        await _storage.saveTokens(accessToken, refreshToken);
        await _storage.saveUsername(username);
        _api.setToken(accessToken);

        _user = UserModel(
          username: username,
          email: '',
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        await _storage.saveUser(jsonEncode(_user!.toJson()));
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      };

      final response = await _api.signup(userData);
      // extract tokens from signup response and persist (signup returns access/refresh)
      final accessToken = response['access'];
      final refreshToken = response['refresh'];

      // build user model from response fields where available
      _user = UserModel(
        username: response['username'] ?? username,
        email: response['email'] ?? email,
        firstName: response['first_name'] ?? firstName ?? '',
        lastName: response['last_name'] ?? lastName ?? '',
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (accessToken != null && refreshToken != null) {
        await _storage.saveTokens(accessToken, refreshToken);
        await _storage.saveUser(jsonEncode(_user!.toJson()));
        await _storage.saveUsername(username);
        _api.setToken(accessToken);
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}