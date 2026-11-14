import 'package:artvard/main.dart';
import 'package:artvard/models/api_response.dart';
import 'package:artvard/providers/object_provider.dart';
import 'package:artvard/services/harvard_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHarvardApi extends HarvardApi {
  @override
  Future<ApiResponse> fetchObjects({
    int page = 1,
    int size = 20,
    String? classification,
    String? title,
  }) async {
    return const ApiResponse(info: ApiInfo(), records: []);
  }
}

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [harvardApiProvider.overrideWithValue(_FakeHarvardApi())],
        child: const ArtvardApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Artvard'), findsOneWidget);
  });
}
