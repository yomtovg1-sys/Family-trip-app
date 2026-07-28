import 'package:flutter/material.dart';

Future<String?> showRenameDocumentDialog(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename Document'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'File name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            Navigator.of(context).pop(value.isEmpty ? currentName : value);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
