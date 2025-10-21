import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_translator/app/app.dart';

void main() async {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
    Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY']!);
  });

  testWidgets('App shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LiveTranslatorApp());
    await tester.pumpAndSettle();

    // Verify that our counter starts at 0.
    expect(find.text('Live Translator Home Page'), findsOneWidget);
  });
}