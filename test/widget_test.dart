import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Cybershield/main.dart'; // Make sure this path is correct

void main() {
  testWidgets('CyberShieldApp loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CyberShieldApp());

    // Update the text below to match something actually shown on HomeScreen
    expect(find.text('Welcome'), findsOneWidget);
  });
}
