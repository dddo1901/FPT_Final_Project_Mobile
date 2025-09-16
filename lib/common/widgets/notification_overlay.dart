import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_widget.dart';

class NotificationOverlay extends StatelessWidget {
  final Widget child;

  const NotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              final notifications = notificationProvider.notifications;

              return Column(
                children: notifications.map((notification) {
                  return NotificationWidget(
                    notification: notification,
                    onDismiss: () {
                      notificationProvider.removeNotification(notification.id);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            final confirmModal = notificationProvider.confirmModal;
            if (confirmModal == null) return const SizedBox.shrink();

            return Container(
              color: Colors.black54,
              child: Center(
                child: AlertDialog(
                  title: Text(confirmModal.title),
                  content: Text(confirmModal.message),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: confirmModal.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            confirmModal.cancelColor ?? Colors.grey[600],
                      ),
                      child: Text(confirmModal.cancelText),
                    ),
                    ElevatedButton(
                      onPressed: confirmModal.onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            confirmModal.confirmColor ??
                            Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(confirmModal.confirmText),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
