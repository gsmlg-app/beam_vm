import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm_example/main.dart';

void main() {
  testWidgets('App displays status information', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('BEAM VM Example'), findsOneWidget);
    expect(find.textContaining('OTP Version:'), findsOneWidget);
    expect(find.textContaining('Status:'), findsOneWidget);
  });
}
