import 'object_record.dart';

class ApiInfo {
  final int page;
  final int pages;
  final int totalRecords;

  const ApiInfo({this.page = 1, this.pages = 1, this.totalRecords = 0});

  factory ApiInfo.fromJson(Map<String, dynamic> json) {
    return ApiInfo(
      page: _intFromJson(json['page']) ?? 1,
      pages: _intFromJson(json['pages']) ?? 1,
      totalRecords: _intFromJson(json['totalrecords']) ?? 0,
    );
  }

  bool get hasMore => page < pages;
}

class ApiResponse {
  final ApiInfo info;
  final List<ObjectRecord> records;

  const ApiResponse({required this.info, required this.records});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    final infoJson = json['info'];
    final recordsJson = json['records'];

    return ApiResponse(
      info: infoJson is Map<String, dynamic>
          ? ApiInfo.fromJson(infoJson)
          : const ApiInfo(),
      records: recordsJson is List
          ? recordsJson
                .whereType<Map<String, dynamic>>()
                .map(ObjectRecord.fromJson)
                .toList()
          : const <ObjectRecord>[],
    );
  }
}

int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
