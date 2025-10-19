import 'package:flutter/material.dart';
import 'package:live_translator/shared/utils/env_util.dart';
import 'package:live_translator/src/home/presentation/home_screen.dart';

class LiveTranslatorApp extends StatelessWidget {
  const LiveTranslatorApp
({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EnvUtil().APP_TITLE,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: '${EnvUtil().APP_TITLE} Home Page'),
    );
  }
}
