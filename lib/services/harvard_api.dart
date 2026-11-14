import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';

class HarvardApiException implements Exception {
  final String message;
  final int? statusCode;

  HarvardApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class HarvardApi {
  static const String baseHost = 'api.harvardartmuseums.org';
  static const String apiKey = 'YOUR_HARVARD_API_KEY_HERE';

  final http.Client _client;

  HarvardApi({http.Client? client}) : _client = client ?? http.Client();

  Future<ApiResponse> fetchObjects({
    int page = 1,
    int size = 20,
    bool hasImage = true,
    String? classification,
    String? title,
  }) async {
    final params = <String, String>{
      'apikey': apiKey,
      'size': size.toString(),
      'page': page.toString(),
    };

    if (hasImage) {
      params['hasimage'] = '1';
    }

    final classificationValue = classification?.trim();
    if (classificationValue != null && classificationValue.isNotEmpty) {
      params['classification'] = classificationValue;
    }

    final titleValue = title?.trim();
    if (titleValue != null && titleValue.isNotEmpty) {
      params['title'] = titleValue;
    }

    final uri = Uri.https(baseHost, '/object', params);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw HarvardApiException('Неверный API ключ', statusCode: 401);
    }

    if (response.statusCode == 429) {
      throw HarvardApiException(
        'Превышен лимит запросов (2500/день)',
        statusCode: 429,
      );
    }

    throw HarvardApiException(
      'Ошибка загрузки (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }
}
