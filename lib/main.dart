import 'package:flutter/material.dart';
import 'melody_quiz_page.dart';
import 'package:flutter/services.dart';

// ✅ 앱의 진입점 (entry point)
// - 화면을 가로모드로 고정
// - MelodyQuizPage()를 앱의 홈 화면으로 설정


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MaterialApp(home: MelodyQuizPage()));
  });
}

