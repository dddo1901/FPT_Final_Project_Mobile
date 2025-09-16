import 'package:flutter/material.dart';
import '../../common/extensions/notification_extension.dart';
import '../../common/widgets/notification_icon.dart';

class NotificationDemoPage extends StatelessWidget {
  const NotificationDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: const [NotificationIcon()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification System Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Test different types of notifications and dialogs',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Success Notification
            ElevatedButton.icon(
              onPressed: () {
                context.showSuccess('This is a success message!');
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Show Success'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Error Notification
            ElevatedButton.icon(
              onPressed: () {
                context.showError(
                  'Something went wrong! This is an error message.',
                );
              },
              icon: const Icon(Icons.error),
              label: const Text('Show Error'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Warning Notification
            ElevatedButton.icon(
              onPressed: () {
                context.showWarning(
                  'This is a warning message. Please be careful!',
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Show Warning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Info Notification
            ElevatedButton.icon(
              onPressed: () {
                context.showInfo('Here is some useful information for you.');
              },
              icon: const Icon(Icons.info),
              label: const Text('Show Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Dialog
            ElevatedButton.icon(
              onPressed: () async {
                final result = await context.showConfirm(
                  title: 'Delete Item',
                  message:
                      'Are you sure you want to delete this item? This action cannot be undone.',
                  confirmText: 'Delete',
                  cancelText: 'Cancel',
                  confirmColor: Colors.red,
                );

                if (result) {
                  context.showSuccess('Item deleted successfully');
                } else {
                  context.showInfo('Delete cancelled');
                }
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Show Confirm Dialog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Custom Duration Notification
            ElevatedButton.icon(
              onPressed: () {
                context.showInfo(
                  'This notification will stay for 10 seconds',
                  duration: const Duration(seconds: 10),
                );
              },
              icon: const Icon(Icons.timer),
              label: const Text('Long Duration Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Clear All Notifications
            OutlinedButton.icon(
              onPressed: () {
                context.clearNotifications();
                context.showInfo('All notifications cleared');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Notifications'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
