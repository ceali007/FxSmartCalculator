// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/ocr_screen.dart';

void main() {
  runApp(FxSmartCalculatorApp());
}

class FxSmartCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FxSmartCalculator',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: OcrScreen(),
    );
  }
}
