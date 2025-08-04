import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/ocr_parser.dart';

class OcrScreen extends StatefulWidget {
  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _image;
  ParsedTradeData? _tradeData;
  final TextEditingController _lotController = TextEditingController();

  Future<void> _pickAndParseImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    final imageFile = File(pickedImage.path);
    final inputImage = InputImage.fromFile(imageFile);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final result = OCRParser.parse(recognizedText);

    setState(() {
      _image = imageFile;
      _tradeData = result;
    });
  }

  double? _calculatePnL(double lot) {
    if (_tradeData == null || _tradeData!.price == null) return null;
    final price = _tradeData!.price!;
    final tpPnl = (_tradeData!.tp != null) ? (_tradeData!.tp! - price) * lot : 0;
    final slPnl = (_tradeData!.sl != null) ? (price - _tradeData!.sl!) * lot : 0;

    return (tpPnl != 0 ? tpPnl : -slPnl).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _tradeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fx Smart Calculator OCR'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndParseImage,
              child: const Text('Resim Yükle ve Oku'),
            ),
            const SizedBox(height: 10),
            if (_image != null)
              Image.file(
                _image!,
                height: MediaQuery.of(context).size.height * 0.5,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 10),
            if (parsed != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sembol: ${parsed.symbol ?? 'Bulunamadı'}"),
                  Text("İşlem Fiyatı: ${parsed.price?.toStringAsFixed(2) ?? 'Bulunamadı'}"),
                  Text("TP: ${parsed.tp?.toStringAsFixed(2) ?? 'Bulunamadı'}"),
                  Text("SL: ${parsed.sl?.toStringAsFixed(2) ?? 'Bulunamadı'}"),
                ],
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _lotController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Lot Miktarı'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final lot = double.tryParse(_lotController.text);
                if (lot == null || parsed == null) return;

                final result = _calculatePnL(lot);
                final text = result != null ? 'Hesaplanan Kar/Zarar: ${result.toStringAsFixed(2)}' : 'Hesaplama yapılamadı';

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sonuç'),
                    content: Text(text),
                  ),
                );
              },
              child: const Text('Kâr / Zarar Hesapla'),
            ),
          ],
        ),
      ),
    );
  }
}
