import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

extension NotificationExtension on BuildContext {
  NotificationProvider get notification =>
      Provider.of<NotificationProvider>(this, listen: false);

  // Show success notification
  String showSuccess(
    String message, {
    String title = 'Success',
    bool autoClose = true,
    Duration duration = const Duration(seconds: 5),
  }) {
    return notification.showSuccess(
      message,
      title: title,
      autoClose: autoClose,
      duration: duration,
    );
  }

  // Show error notification
  String showError(
    String message, {
    String title = 'Error',
    bool autoClose = false,
    Duration duration = const Duration(seconds: 10),
  }) {
    return notification.showError(
      message,
      title: title,
      autoClose: autoClose,
      duration: duration,
    );
  }

  // Show warning notification
  String showWarning(
    String message, {
    String title = 'Warning',
    bool autoClose = true,
    Duration duration = const Duration(seconds: 7),
  }) {
    return notification.showWarning(
      message,
      title: title,
      autoClose: autoClose,
      duration: duration,
    );
  }

  // Show info notification
  String showInfo(
    String message, {
    String title = 'Information',
    bool autoClose = true,
    Duration duration = const Duration(seconds: 5),
  }) {
    return notification.showInfo(
      message,
      title: title,
      autoClose: autoClose,
      duration: duration,
    );
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
    return notification.showConfirm(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      cancelColor: cancelColor,
    );
  }

  // Clear all notifications
  void clearNotifications() {
    notification.clearNotifications();
  }

  // Mark notification as read
  void markNotificationAsRead(String id) {
    notification.markAsRead(id);
  }

  // Mark all notifications as read
  void markAllNotificationsAsRead() {
    notification.markAllAsRead();
  }

  // Get unread count
  int get unreadNotificationCount => notification.unreadCount;
}
