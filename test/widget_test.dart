import 'package:flutter_test/flutter_test.dart';
import 'package:voice_agent_flutter/main.dart';

void main() {
  testWidgets('Axel arranca y muestra el título', (tester) async {
    await tester.pumpWidget(const AxelApp());
    expect(find.text('AXEL'), findsWidgets);
  });
}