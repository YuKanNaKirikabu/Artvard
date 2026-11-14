import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/object_record.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
      (ref) => FavoritesNotifier(),
    );

class FavoritesState {
  final Map<int, ObjectRecord> items;
  final bool isLoaded;

  const FavoritesState({required this.items, required this.isLoaded});

  factory FavoritesState.initial() {
    return const FavoritesState(items: {}, isLoaded: false);
  }

  bool contains(int id) => items.containsKey(id);

  List<ObjectRecord> get records => items.values.toList();

  bool get isEmpty => items.isEmpty;
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  static const String _storageKey = 'favorites_records';

  FavoritesNotifier() : super(FavoritesState.initial()) {
    _load();
  }

  Future<void> toggle(ObjectRecord record) async {
    final updated = Map<int, ObjectRecord>.from(state.items);

    if (updated.containsKey(record.id)) {
      updated.remove(record.id);
    } else {
      updated[record.id] = record;
    }

    state = FavoritesState(items: updated, isLoaded: true);
    await _save(updated);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      state = FavoritesState(items: state.items, isLoaded: true);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        state = FavoritesState(items: state.items, isLoaded: true);
        return;
      }

      final items = <int, ObjectRecord>{};
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          final record = ObjectRecord.fromStorage(entry);
          items[record.id] = record;
        }
      }

      state = FavoritesState(items: items, isLoaded: true);
    } catch (_) {
      state = FavoritesState(items: state.items, isLoaded: true);
    }
  }

  Future<void> _save(Map<int, ObjectRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items.values
        .map((record) => record.toStorageJson())
        .toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}
