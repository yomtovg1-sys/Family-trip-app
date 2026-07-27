import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/photo_entry.dart';
import '../providers/photo_journal_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';

class PhotoJournalScreen extends StatelessWidget {
  const PhotoJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<PhotoJournalProvider>().photos;

    return Scaffold(
      appBar: AppBar(title: const Text('Photo Journal')),
      drawer: const AppDrawer(currentRoute: AppSection.photosRoute),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPhotoMemory(context),
        child: const Icon(Icons.add_a_photo),
      ),
      body: photos.isEmpty
          ? const Center(child: Text('No memories yet. Add your first one!'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) => _PhotoCard(photo: photos[index]),
            ),
    );
  }

  void _addPhotoMemory(BuildContext context) {
    final provider = context.read<PhotoJournalProvider>();
    provider.addPhoto(
      PhotoEntry(
        id: 'ph${DateTime.now().millisecondsSinceEpoch}',
        caption: 'New family memory',
        takenBy: 'Family',
        date: DateTime.now(),
        emoji: '📸',
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final PhotoEntry photo;

  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              alignment: Alignment.center,
              child: Text(photo.emoji, style: const TextStyle(fontSize: 48)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(photo.caption, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${photo.takenBy} · ${dateFormat.format(photo.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
