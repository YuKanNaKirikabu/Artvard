import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorites_provider.dart';
import '../providers/object_provider.dart';
import '../widgets/object_card.dart';
import '../widgets/search_bar.dart';
import 'detail_screen.dart';

const List<String> _classifications = [
  'All',
  'Paintings',
  'Sculpture',
  'Photographs',
  'Prints',
  'Drawings',
  'Textile Arts',
  'Furniture',
  'Ceramics',
  'Metalwork',
];

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 300.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      ref.read(objectListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ObjectListState>(objectListProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.records.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(objectListProvider);
    final notifier = ref.read(objectListProvider.notifier);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artvard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _FilterBar(
              currentClassification: state.classification,
              query: state.query,
              onClassificationChanged: notifier.setClassification,
              onQueryChanged: notifier.setQuery,
            ),
          ),
        ),
      ),
      body: _buildBody(context, state, notifier, favorites),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ObjectListState state,
    ObjectListNotifier notifier,
    FavoritesState favorites,
  ) {
    if (state.isLoading && state.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.records.isEmpty) {
      return _ErrorStateView(
        message: state.errorMessage!,
        isOffline: state.isOffline,
        onRetry: notifier.refresh,
      );
    }

    if (state.records.isEmpty) {
      return _EmptyStateView(onRetry: notifier.refresh);
    }

    final showFooter =
        state.isLoading ||
        (state.errorMessage != null && state.records.isNotEmpty);
    final itemCount = state.records.length + (showFooter ? 1 : 0);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= state.records.length) {
            return _ListFooter(state: state);
          }

          final record = state.records[index];
          return ObjectCard(
            record: record,
            isFavorite: favorites.contains(record.id),
            onFavoriteToggle: () {
              ref.read(favoritesProvider.notifier).toggle(record);
            },
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailScreen(record: record)),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? currentClassification;
  final String query;
  final ValueChanged<String?> onClassificationChanged;
  final ValueChanged<String> onQueryChanged;

  const _FilterBar({
    required this.currentClassification,
    required this.query,
    required this.onClassificationChanged,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final selection =
            _classifications.contains(currentClassification ?? 'All')
            ? (currentClassification ?? 'All')
            : 'All';

        final classificationField = DropdownButtonFormField<String>(
          key: ValueKey(selection),
          initialValue: selection,
          decoration: const InputDecoration(
            labelText: 'Classification',
            border: OutlineInputBorder(),
          ),
          items: _classifications
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onClassificationChanged(value == 'All' ? null : value);
          },
        );

        final searchField = SearchBarField(
          initialText: query,
          hintText: 'Search by title',
          onQueryChanged: onQueryChanged,
        );

        if (isWide) {
          return Row(
            children: [
              SizedBox(width: 220, child: classificationField),
              const SizedBox(width: 12),
              Expanded(child: searchField),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            classificationField,
            const SizedBox(height: 12),
            searchField,
          ],
        );
      },
    );
  }
}

class _ListFooter extends StatelessWidget {
  final ObjectListState state;

  const _ListFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null && state.records.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            state.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ErrorStateView extends StatelessWidget {
  final String message;
  final bool isOffline;
  final VoidCallback onRetry;

  const _ErrorStateView({
    required this.message,
    required this.isOffline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isOffline ? Icons.wifi_off : Icons.error_outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyStateView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text(
              'No objects found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
