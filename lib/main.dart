import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:live_translator/app/app.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const LiveTranslatorApp());
}