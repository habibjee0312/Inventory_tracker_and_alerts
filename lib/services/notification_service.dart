import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  Future<void> showExpiryNotification(String itemName, int daysLeft) async {
    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Notifications',
      channelDescription: 'Notifications for item expiry',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Item Expiring Soon!',
      '$itemName will expire in $daysLeft days',
      notificationDetails,
    );
  }

  Future<void> showLowStockNotification(String itemName, int quantity) async {
    const androidDetails = AndroidNotificationDetails(
      'stock_channel',
      'Stock Notifications',
      channelDescription: 'Notifications for low stock',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Low Stock Alert!',
      '$itemName is running low (only $quantity left)',
      notificationDetails,
    );
  }

  Future<void> showExpiredNotification(String itemName) async {
    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Notifications',
      channelDescription: 'Notifications for item expiry',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2,
      'Item Expired!',
      '$itemName has expired',
      notificationDetails,
    );
  }
}