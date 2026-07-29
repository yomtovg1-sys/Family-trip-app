import 'package:flutter/material.dart';

/// The one confirm/cancel dialog used everywhere the app needs a yes/no
/// check before an action (deleting something, restoring a backup, applying
/// a template). Returns true only if the user tapped [confirmLabel].
///
/// Set [isDestructive] for actions that permanently remove something — it
/// colors the confirm button with the error color, the same visual cue
/// every delete confirmation in the app should share.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
