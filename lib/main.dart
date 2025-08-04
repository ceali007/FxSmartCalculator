import 'package:flutter/material.dart';
import 'screens/ocr_screen.dart';

void main() {
  runApp(FxSmartCalculatorApp());
}

class FxSmartCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fx Smart Calculator',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: OcrScreen(), // const kaldırıldı
      debugShowCheckedModeBanner: false,
    );
  }
}
