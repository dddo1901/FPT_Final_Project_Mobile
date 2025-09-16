import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

enum NotificationPriority { low, medium, high }

class NotificationData {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final bool autoClose;
  final Duration duration;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  bool isRead;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.priority = NotificationPriority.low,
    this.autoClose = true,
    this.duration = const Duration(seconds: 5),
    required this.timestamp,
    this.onTap,
    this.onDismiss,
    this.isRead = false,
  });

  Color get backgroundColor {
    switch (type) {
      case NotificationType.success:
        return Colors.green[600]!;
      case NotificationType.error:
        return Colors.red[600]!;
      case NotificationType.warning:
        return Colors.orange[600]!;
      case NotificationType.info:
        return Colors.blue[600]!;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }
}

class ConfirmDialogData {
  final String id;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Color? confirmColor;
  final Color? cancelColor;

  ConfirmDialogData({
    required this.id,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    required this.onCancel,
    this.confirmColor,
    this.cancelColor,
  });
}
