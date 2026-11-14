import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/object_record.dart';
import '../services/harvard_api.dart';

final harvardApiProvider = Provider<HarvardApi>((ref) => HarvardApi());

final objectListProvider =
    StateNotifierProvider<ObjectListNotifier, ObjectListState>(
      (ref) => ObjectListNotifier(ref.watch(harvardApiProvider)),
    );

class ObjectListState {
  final List<ObjectRecord> records;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final int page;
  final String? errorMessage;
  final bool isOffline;
  final String? classification;
  final String query;

  const ObjectListState({
    required this.records,
    required this.isLoading,
    required this.isRefreshing,
    required this.hasMore,
    required this.page,
    required this.errorMessage,
    required this.isOffline,
    required this.classification,
    required this.query,
  });

  factory ObjectListState.initial() {
    return const ObjectListState(
      records: [],
      isLoading: true,
      isRefreshing: false,
      hasMore: true,
      page: 1,
      errorMessage: null,
      isOffline: false,
      classification: null,
      query: '',
    );
  }

  ObjectListState copyWith({
    List<ObjectRecord>? records,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool? isOffline,
    String? classification,
    String? query,
  }) {
    return ObjectListState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      classification: classification ?? this.classification,
      query: query ?? this.query,
    );
  }
}

class ObjectListNotifier extends StateNotifier<ObjectListState> {
  static const int _pageSize = 20;

  final HarvardApi _api;

  ObjectListNotifier(this._api) : super(ObjectListState.initial()) {
    refresh();
  }

  List<ObjectRecord> _withImages(List<ObjectRecord> records) {
    return records
        .where((record) => record.imageCandidates().isNotEmpty)
        .toList();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      isLoading: state.records.isEmpty,
      errorMessage: null,
      isOffline: false,
      page: 1,
      hasMore: true,
    );

    try {
      final response = await _api.fetchObjects(
        page: 1,
        size: _pageSize,
        classification: state.classification,
        title: state.query,
      );

      final filteredRecords = _withImages(response.records);

      state = state.copyWith(
        records: filteredRecords,
        page: response.info.page,
        hasMore: response.info.hasMore,
        isRefreshing: false,
        isLoading: false,
        errorMessage: null,
        isOffline: false,
      );
    } on SocketException {
      state = state.copyWith(
        isRefreshing: false,
        isLoading: false,
        errorMessage: 'Нет подключения к интернету',
        isOffline: true,
      );
    } on HarvardApiException catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        isLoading: false,
        errorMessage: e.message,
        isOffline: false,
      );
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        isLoading: false,
        errorMessage: 'Не удалось загрузить данные',
        isOffline: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isRefreshing || !state.hasMore) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isOffline: false,
    );

    try {
      final response = await _api.fetchObjects(
        page: state.page + 1,
        size: _pageSize,
        classification: state.classification,
        title: state.query,
      );

      final filteredRecords = _withImages(response.records);
      final merged = [...state.records, ...filteredRecords];

      state = state.copyWith(
        records: merged,
        page: response.info.page,
        hasMore: response.info.hasMore,
        isLoading: false,
        errorMessage: null,
        isOffline: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Нет подключения к интернету',
        isOffline: true,
      );
    } on HarvardApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isOffline: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Не удалось загрузить данные',
        isOffline: false,
      );
    }
  }

  Future<void> setClassification(String? classification) async {
    final normalized = (classification == null || classification == 'All')
        ? null
        : classification;

    if (normalized == state.classification) return;

    state = state.copyWith(
      classification: normalized,
      errorMessage: null,
      isOffline: false,
    );

    await refresh();
  }

  Future<void> setQuery(String query) async {
    final normalized = query.trim();
    if (normalized == state.query) return;

    state = state.copyWith(
      query: normalized,
      errorMessage: null,
      isOffline: false,
    );

    await refresh();
  }
}
