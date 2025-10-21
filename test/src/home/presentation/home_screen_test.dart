import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_translator/src/home/presentation/home_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([SpeechToText, Gemini])
void main() {
  late MockSpeechToText mockSpeechToText;
  late MockGemini mockGemini;

  setUp(() {
    mockSpeechToText = MockSpeechToText();
    mockGemini = MockGemini();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MyHomePage(
        title: 'Live Translator',
        speechToText: mockSpeechToText,
        gemini: mockGemini,
      ),
    );
  }

  testWidgets('Initial UI is rendered correctly when speech is enabled', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => true);
    when(mockSpeechToText.isListening).thenReturn(false);
    when(mockSpeechToText.isNotListening).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.pumpAndSettle();

    expect(find.text('Live Translator'), findsOneWidget);
    expect(find.text('Tap the microphone to start listening...'), findsOneWidget);
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
  });

  testWidgets('Initial UI is rendered correctly when speech is not available', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => false);
    when(mockSpeechToText.isListening).thenReturn(false);
    when(mockSpeechToText.isNotListening).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.pumpAndSettle();

    expect(find.text('Speech not available'), findsOneWidget);
  });

  testWidgets('Tap microphone to start and stop listening', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => true);
    when(mockSpeechToText.isListening).thenReturn(false);
    when(mockSpeechToText.isNotListening).thenReturn(true);
    when(mockSpeechToText.listen(onResult: anyNamed('onResult'), localeId: anyNamed('localeId')))
        .thenAnswer((_) async => true);
    when(mockSpeechToText.stop()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.pumpAndSettle();

    // Start listening
    when(mockSpeechToText.isListening).thenReturn(true);
    when(mockSpeechToText.isNotListening).thenReturn(false);
    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pump();

    expect(find.byIcon(Icons.mic), findsOneWidget);
    verify(mockSpeechToText.listen(onResult: anyNamed('onResult'), localeId: 'in-ID')).called(1);

    // Stop listening
    when(mockSpeechToText.isListening).thenReturn(false);
    when(mockSpeechToText.isNotListening).thenReturn(true);
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    verify(mockSpeechToText.stop()).called(1);
  });

  testWidgets('Speech recognition result updates the UI', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => true);
    when(mockSpeechToText.isListening).thenReturn(false);
    when(mockSpeechToText.isNotListening).thenReturn(true);
    when(mockSpeechToText.listen(onResult: anyNamed('onResult'), localeId: anyNamed('localeId')))
        .thenAnswer((invocation) async {
      final onResult = invocation.namedArguments[#onResult] as Function(SpeechRecognitionResult);
      onResult(SpeechRecognitionResult([const SpeechRecognitionWords('Hello', 1.0)], true));
      return true;
    });
    when(mockGemini.promptStream(model: anyNamed('model'), parts: anyNamed('parts')))
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pump();

    expect(find.text('Spoken words: Hello'), findsOneWidget);
  });

  testWidgets('Translation result updates the UI', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => true);
    when(mockSpeechToText.isListening).thenReturn(false);
    when(mockSpeechToText.isNotListening).thenReturn(true);
    when(mockSpeechToText.listen(onResult: anyNamed('onResult'), localeId: anyNamed('localeId')))
        .thenAnswer((invocation) async {
      final onResult = invocation.namedArguments[#onResult] as Function(SpeechRecognitionResult);
      onResult(SpeechRecognitionResult([const SpeechRecognitionWords('Halo', 1.0)], true));
      return true;
    });

    final geminiResponse = GeminiResponse(
      candidates: [
        Candidates(
          content: Content(parts: [TextPart('Hello')]),
          finishReason: 'FinishReason.stop',
          index: 0,
          safetyRatings: [],
        )
      ],
    );

    when(mockGemini.promptStream(model: anyNamed('model'), parts: anyNamed('parts')))
        .thenAnswer((_) => Stream.value(geminiResponse.candidates?[0]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle(const Duration(milliseconds: 1100));

    expect(find.text('Spoken words: Halo'), findsOneWidget);
    expect(find.text('Translation: Hello'), findsOneWidget);
  });
}
