import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class InventoryViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final NotificationService _notifications = NotificationService();

  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ItemModel> get expiringItems => _items.where((i) => i.isExpiringSoon).toList();
  List<ItemModel> get expiredItems => _items.where((i) => i.hasExpired).toList();
  List<ItemModel> get lowStockItems => _items.where((i) => i.isLowOnStock).toList();

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getItems();
      _items = response.map((json) => ItemModel.fromJson(json)).toList();
      _checkNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(ItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.addItem(item);
      await loadItems();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(int id, ItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateItem(id, item);
      await loadItems();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      await _api.deleteItem(id);
      await loadItems();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _checkNotifications() {
    for (final item in _items) {
      if (item.hasExpired) {
        _notifications.showExpiredNotification(item.name);
      } else if (item.isExpiringSoon) {
        final daysLeft = item.daysRemaining ?? item.expiry.difference(DateTime.now()).inDays;
        _notifications.showExpiryNotification(item.name, daysLeft);
      }

      if (item.isLowOnStock && !item.hasExpired) {
        _notifications.showLowStockNotification(item.name, item.quantity);
      }
    }
  }
}
