import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/notification_data.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationData> _notifications = [];
  final List<NotificationData> _notificationHistory = [];
  ConfirmDialogData? _confirmModal;

  List<NotificationData> get notifications => List.unmodifiable(_notifications);
  List<NotificationData> get notificationHistory =>
      List.unmodifiable(_notificationHistory);
  ConfirmDialogData? get confirmModal => _confirmModal;

  // Count unread notifications
  int get unreadCount => _notificationHistory.where((n) => !n.isRead).length;

  // Generate unique ID for notifications
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_$random';
  }

  // Add notification
  String addNotification(NotificationData notification) {
    _notifications.add(notification);
    // Also add to history
    _notificationHistory.insert(
      0,
      notification,
    ); // Insert at beginning for newest first
    notifyListeners();

    // Auto remove if autoClose is enabled
    if (notification.autoClose) {
      Timer(notification.duration, () {
        removeNotification(notification.id);
      });
    }

    return notification.id;
  }

  // Remove notification (only from active notifications, keep in history)
  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
  }

  // Clear all active notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Mark notification as read
  void markAsRead(String id) {
    final index = _notificationHistory.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificationHistory[index].isRead = true;
      notifyListeners();
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notificationHistory) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  // Clear notification history
  void clearHistory() {
    _notificationHistory.clear();
    notifyListeners();
  }

  // Show success notification
  String showSuccess(
    String message, {
    String title = 'Success',
    NotificationPriority priority = NotificationPriority.low,
    bool autoClose = true,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final notification = NotificationData(
      id: _generateId(),
      type: NotificationType.success,
      title: title,
      message: message,
      priority: priority,
      autoClose: autoClose,
      duration: duration,
      timestamp: DateTime.now(),
      onTap: onTap,
      onDismiss: onDismiss,
    );
    return addNotification(notification);
  }

  // Show error notification
  String showError(
    String message, {
    String title = 'Error',
    NotificationPriority priority = NotificationPriority.high,
    bool autoClose = false, // Errors should be manually dismissed
    Duration duration = const Duration(seconds: 10),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final notification = NotificationData(
      id: _generateId(),
      type: NotificationType.error,
      title: title,
      message: message,
      priority: priority,
      autoClose: autoClose,
      duration: duration,
      timestamp: DateTime.now(),
      onTap: onTap,
      onDismiss: onDismiss,
    );
    return addNotification(notification);
  }

  // Show warning notification
  String showWarning(
    String message, {
    String title = 'Warning',
    NotificationPriority priority = NotificationPriority.medium,
    bool autoClose = true,
    Duration duration = const Duration(seconds: 7),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final notification = NotificationData(
      id: _generateId(),
      type: NotificationType.warning,
      title: title,
      message: message,
      priority: priority,
      autoClose: autoClose,
      duration: duration,
      timestamp: DateTime.now(),
      onTap: onTap,
      onDismiss: onDismiss,
    );
    return addNotification(notification);
  }

  // Show info notification
  String showInfo(
    String message, {
    String title = 'Information',
    NotificationPriority priority = NotificationPriority.low,
    bool autoClose = true,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final notification = NotificationData(
      id: _generateId(),
      type: NotificationType.info,
      title: title,
      message: message,
      priority: priority,
      autoClose: autoClose,
      duration: duration,
      timestamp: DateTime.now(),
      onTap: onTap,
      onDismiss: onDismiss,
    );
    return addNotification(notification);
  }

  // Show confirm dialog
  Future<bool> showConfirm({
    String title = 'Confirm Action',
    String message = 'Are you sure?',
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? cancelColor,
  }) {
    final completer = Completer<bool>();
    final id = _generateId();

    _confirmModal = ConfirmDialogData(
      id: id,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      cancelColor: cancelColor,
      onConfirm: () {
        _confirmModal = null;
        notifyListeners();
        completer.complete(true);
      },
      onCancel: () {
        _confirmModal = null;
        notifyListeners();
        completer.complete(false);
      },
    );

    notifyListeners();
    return completer.future;
  }

  // Close confirm modal
  void closeConfirm() {
    if (_confirmModal != null) {
      _confirmModal!.onCancel();
    }
  }
}
