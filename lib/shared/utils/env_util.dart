// ignore_for_file: non_constant_identifier_names

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvUtil {
  final String APP_TITLE = dotenv.env['APP_TITLE'] ?? 'Live Translator';

  // To be changed
  final String GEMINI_API_KEY = dotenv.env['GEMINI_API_KEY'] ?? '';
}