import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:live_translator/shared/constants/gemini_constant.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.speechToText,
    this.gemini,
  });

  final String title;
  final SpeechToText? speechToText;
  final Gemini? gemini;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final SpeechToText _speechToText;
  late final Gemini _gemini;
  final Debouncer _translatorApiDebouncer = Debouncer();

  bool _speechEnabled = false;
  String _lastWords = '';
  String _translations = '';

  @override
  void initState() {
    super.initState();

    _speechToText = widget.speechToText ?? SpeechToText();
    _gemini = widget.gemini ?? Gemini.instance;

    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();

    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    // Try Indonesian
    await _speechToText.listen(onResult: _onSpeechResult, localeId: 'in-ID');
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    _debounceTranslate(result.recognizedWords);
  }

  void _debounceTranslate(String recognizedWords) {
    _translatorApiDebouncer.debounce(
        duration: const Duration(milliseconds: 1000),
        onDebounce: () {
          _translateThroughPrompt(recognizedWords);
        });
  }

  /// Handle gemini prompt
  void _translateThroughPrompt(String recognizedWords) {
    log('Calling Gemini API');
    _gemini.promptStream(
      model: GeminiConstant.GEMINI_MODEL,
      parts: [
        Part.text(
            'Translate the following words from Indonesian to English. '
            'Your response should just be the translation and nothing else. '
            'Words to be translated: $recognizedWords'),
      ],
    ).listen((value) {
      if (value == null) return;

      setState(() {
        _translations = value.output ?? '';
      });
    }).onError((error, trace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar(error.toString()));
      }
    });
  }

  SnackBar _errorSnackBar(String? message) {
    return SnackBar(
        content: Text('Error: ${message ?? 'Unknown error occured'}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _speechToText.isListening || _lastWords.isNotEmpty
                  ? 'Spoken words: $_lastWords'
                  // If listening isn't active but could be tell the user
                  // how to start it, otherwise indicate that speech
                  // recognition is not yet ready or not supported on
                  // the target device
                  : _speechEnabled
                      ? 'Tap the microphone to start listening...'
                      : 'Speech not available',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Translation: $_translations',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            // If not yet listening for speech start, otherwise stop
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
