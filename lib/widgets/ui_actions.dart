import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fpt_final_project_mobile/auths/auth_provider.dart';

Future<void> confirmAndLogout(
  BuildContext context, {
  String title = 'Sign out?',
  String message = 'Are you sure you want to sign out?',
  String cancelText = 'Cancel',
  String confirmText = 'Sign out',
  bool closeDrawerOnCancel = true,
}) async {
  final auth = context.read<AuthProvider>();
  final navigator = Navigator.of(context, rootNavigator: true);
  final navForDrawer = Navigator.of(context);

  final bool ok =
      await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogCtx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      ) ??
      false;

  if (ok) {
    await auth.logout();
    // Use navigator captured before async operation
    navigator.pushNamedAndRemoveUntil('/', (_) => false);
  } else {
    if (closeDrawerOnCancel && navForDrawer.canPop()) {
      navForDrawer.pop();
    }
  }
}
