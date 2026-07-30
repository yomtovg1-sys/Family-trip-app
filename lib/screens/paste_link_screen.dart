import 'package:flutter/material.dart';
import '../models/place_draft.dart';
import 'add_place_screen.dart';

/// A generic "paste a link, we'll figure out the place" screen — reused for
/// both "Paste Google Maps URL" (real coordinate parsing, no network) and
/// "Paste website" (mock extraction, architecture-only for now).
class PasteLinkScreen extends StatefulWidget {
  final String title;
  final String hint;
  final String helperText;
  final Future<PlaceDraft?> Function(String link) onParse;
  final String notFoundMessage;

  const PasteLinkScreen({
    super.key,
    required this.title,
    required this.hint,
    required this.helperText,
    required this.onParse,
    required this.notFoundMessage,
  });

  @override
  State<PasteLinkScreen> createState() => _PasteLinkScreenState();
}

class _PasteLinkScreenState extends State<PasteLinkScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final link = _controller.text.trim();
    if (link.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final draft = await widget.onParse(link);
    if (!mounted) return;
    setState(() => _loading = false);
    if (draft == null) {
      setState(() => _error = widget.notFoundMessage);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AddPlaceScreen(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.helperText,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: widget.hint,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _continue,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
