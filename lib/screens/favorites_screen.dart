import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/object_record.dart';
import '../providers/favorites_provider.dart';
import '../widgets/object_card.dart';
import 'detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final records = favorites.records;

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: _buildBody(context, ref, favorites, records),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FavoritesState favorites,
    List<ObjectRecord> records,
  ) {
    if (!favorites.isLoaded && records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return const _EmptyFavoritesView();
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return ObjectCard(
          record: record,
          isFavorite: true,
          onFavoriteToggle: () {
            ref.read(favoritesProvider.notifier).toggle(record);
          },
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailScreen(record: record),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, size: 48),
            const SizedBox(height: 12),
            Text(
              'Пока нет избранных работ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите на звездочку в списке, чтобы добавить.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
