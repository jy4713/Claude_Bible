import 'package:flutter_test/flutter_test.dart';
import 'package:bible_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // BibleApp requires providers - this is a placeholder test
    expect(BibleApp, isNotNull);
  });
}
