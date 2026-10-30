import 'package:flutter_test/flutter_test.dart';
import 'package:dosyax/main.dart';

void main() {
  testWidgets('DosyaX smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DosyaXApp());
    expect(find.text('DosyaX'), findsOneWidget);
  });
}
