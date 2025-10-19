import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:live_translator/app/app.dart';
import 'package:live_translator/shared/utils/env_util.dart';

void main() async {
  // Env setup
  await dotenv.load(fileName: '.env');

  // Gemini setup
  Gemini.init(apiKey: EnvUtil().GEMINI_API_KEY);

  runApp(const LiveTranslatorApp());
}