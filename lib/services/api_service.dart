import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

import '../models/item_model.dart';
import 'storage_service.dart';

class ApiService {

  // Use host machine address for Android emulator, avoid dart:io Platform to prevent Unsupported Operation errors
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android) {
      // Android emulator -> host machine
      return 'http://10.0.2.2:8000/api';
    }
    // iOS simulator, desktop, physical device (replace with LAN IP on physical device if needed)
    return 'http://127.0.0.1:8000/api';
  }

  String? _accessToken;
  final StorageService _storage = StorageService();

  void setToken(String token) {
    _accessToken = token;
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // refresh access token using stored refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null) return false;
      final uri = Uri.parse('${baseUrl}/auth/token/refresh/');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refresh})).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newAccess = data['access'];
        if (newAccess != null) {
          _accessToken = newAccess;
          // persist new access token (keep same refresh)
          await _storage.saveTokens(newAccess, refresh);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // helper: ensure _accessToken is populated from storage if missing
  Future<void> _ensureTokenLoaded() async {
    if (_accessToken == null) {
      final saved = await _storage.getAccessToken();
      if (saved != null && saved.isNotEmpty) {
        _accessToken = saved;
      }
    }
  }

  // helper to retry once after refresh if 401 returned
  Future<http.Response> _getWithRefresh(Uri uri) async {
    await _ensureTokenLoaded();
    var resp = await http.get(uri, headers: _headers());
    if (resp.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        resp = await http.get(uri, headers: _headers());
      }
    }
    return resp;
  }

  Future<http.Response> _postWithRefresh(Uri uri, Object? body, {bool auth = true}) async {
    if (auth) await _ensureTokenLoaded();
    var resp = await http.post(uri, headers: _headers(auth: auth), body: body);
    if (auth && resp.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        resp = await http.post(uri, headers: _headers(auth: auth), body: body);
      }
    }
    return resp;
  }

  Future<http.Response> _putWithRefresh(Uri uri, Object? body) async {
    await _ensureTokenLoaded();
    var resp = await http.put(uri, headers: _headers(), body: body);
    if (resp.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        resp = await http.put(uri, headers: _headers(), body: body);
      }
    }
    return resp;
  }

  Future<http.Response> _patchWithRefresh(Uri uri, Object? body) async {
    await _ensureTokenLoaded();
    var resp = await http.patch(uri, headers: _headers(), body: body);
    if (resp.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        resp = await http.patch(uri, headers: _headers(), body: body);
      }
    }
    return resp;
  }

  Future<http.Response> _deleteWithRefresh(Uri uri) async {
    await _ensureTokenLoaded();
    var resp = await http.delete(uri, headers: _headers());
    if (resp.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        resp = await http.delete(uri, headers: _headers());
      }
    }
    return resp;
  }

  // Auth endpoints - /api/auth/
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final uri = Uri.parse('${baseUrl}/auth/token/');
      final response = await _postWithRefresh(uri, jsonEncode({'username': username, 'password': password}), auth: false)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // persist tokens if present
        if (data['access'] != null && data['refresh'] != null) {
          await _storage.saveTokens(data['access'], data['refresh']);
          _accessToken = data['access'];
        }
        return data;
      } else {
        final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(error is Map ? (error['detail'] ?? 'Login failed') : 'Login failed');
      }
    } catch (e) {
      throw Exception('Could not connect to server. Check your network/host address. (${e.toString()})');
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, String> userData) async {
    try {
      final uri = Uri.parse('${baseUrl}/auth/users/');
      final response = await _postWithRefresh(uri, jsonEncode(userData), auth: false)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // persist tokens if signup returns them
        if (data['access'] != null && data['refresh'] != null) {
          await _storage.saveTokens(data['access'], data['refresh']);
          _accessToken = data['access'];
        }
        return data;
      } else {
        final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        if (error is Map) {
          final firstError = error.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError[0]);
          }
        }
        throw Exception('Signup failed');
      }
    } catch (e) {
      throw Exception('Could not connect to server. Check your network/host address. (${e.toString()})');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] != null) {
          _accessToken = data['access'];
        }
        return data;
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      throw Exception('Could not connect to server. Check your network or host address.');
    }
  }

  // Inventory endpoints - /api/items/
  Future<List<dynamic>> getItems() async {
    final uri = Uri.parse('${baseUrl}/items/');
    final response = await _getWithRefresh(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<Map<String, dynamic>> getItem(int id) async {
    final uri = Uri.parse('${baseUrl}/items/$id/');
    final response = await _getWithRefresh(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load item');
    }
  }

  Future<Map<String, dynamic>> addItem(ItemModel item) async {
    final uri = Uri.parse('${baseUrl}/items/');
    final response = await _postWithRefresh(uri, jsonEncode(item.toJson()));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      if (error is Map) {
        final firstError = error.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError[0]);
        }
      }
      throw Exception('Failed to add item');
    }
  }

  Future<Map<String, dynamic>> updateItem(int id, ItemModel item) async {
    final uri = Uri.parse('${baseUrl}/items/$id/');
    final response = await _putWithRefresh(uri, jsonEncode(item.toJson()));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      if (error is Map) {
        final firstError = error.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError[0]);
        }
      }
      throw Exception('Failed to update item');
    }
  }

  Future<Map<String, dynamic>> partialUpdateItem(int id, Map<String, dynamic> updates) async {
    final uri = Uri.parse('${baseUrl}/items/$id/');
    final response = await _patchWithRefresh(uri, jsonEncode(updates));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update item');
    }
  }

  Future<void> deleteItem(int id) async {
    final uri = Uri.parse('${baseUrl}/items/$id/');
    final response = await _deleteWithRefresh(uri);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }
}
