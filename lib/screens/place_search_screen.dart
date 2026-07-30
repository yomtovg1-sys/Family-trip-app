import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/place_draft.dart';
import '../services/place_extractors.dart';
import 'add_place_screen.dart';

/// "Google Maps search" capture flow: type a place name, pick a result,
/// land on the review form with it pre-filled. Backed by
/// [MockPlaceSearchService] for now — swapping in a real Places API call
/// only means implementing [PlaceSearchService.search].
class PlaceSearchScreen extends StatefulWidget {
  final PlaceSearchService searchService;

  const PlaceSearchScreen({super.key, this.searchService = const MockPlaceSearchService()});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _controller = TextEditingController();
  List<PlaceDraft> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    final results = await widget.searchService.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Google Maps')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search for a restaurant, hotel, attraction…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _search,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searched && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text('No results found.', style: theme.textTheme.bodyMedium),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        child: Text(result.category?.emoji ?? '📍'),
                      ),
                      title: Text(result.name ?? 'Unnamed place'),
                      subtitle: Text(result.area ?? ''),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => AddPlaceScreen(draft: result)),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
