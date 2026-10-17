import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:format_anything/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Format Anything home screen renders', (tester) async {
    await tester.pumpWidget(const FormatAnythingApp());
    await tester.pumpAndSettle();

    expect(find.text('Format Anything'), findsWidgets);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
