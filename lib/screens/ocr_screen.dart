import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
//import '../models/parsed_trade_data.dart';
import '../models/parsed_trade_data.dart';
import '../utils/ocr_parser.dart';
import '../services/symbol_service.dart';
import '../utils/parser_helper.dart';

class OcrScreen extends StatefulWidget {
  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _image;
  ParsedTradeData? _parsedData;
  final TextEditingController _lotController = TextEditingController();
  final TextEditingController _tpController = TextEditingController();
  final TextEditingController _slController = TextEditingController();
  double? _potentialProfit;
  double? _potentialLoss;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _parsedData = null;
        _potentialProfit = null;
        _potentialLoss = null;
      });
      await _processImage(_image!);
    }
  }

  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    textRecognizer.close();

    final parsedResult = OCRParser.parse(recognizedText);

    print('[DEBUG] OCR sembol ham verisi: ${parsedResult.symbol}');
    print('[DEBUG] OCR Parser sonucu sembol: ${parsedResult.symbol}');

    setState(() {
      _parsedData = parsedResult;
      _tpController.text = parsedResult.tp?.toString() ?? '';
      _slController.text = parsedResult.sl?.toString() ?? '';
    });
  }

  void _calculatePnL() async {
    if (_parsedData == null || _parsedData!.price == null) return;

    final lot = double.tryParse(_lotController.text);
    final price = _parsedData!.price!;
    final tp = double.tryParse(_tpController.text);
    final sl = double.tryParse(_slController.text);

    if (lot == null || _parsedData!.symbol == null) return;

    final symbol = await SymbolService().getSymbol(
      ParserHelper.cleanSymbol(_parsedData!.symbol!),
    );

    if (symbol == null) return;

    final contractSize = symbol.contractSize.toDouble();

    setState(() {
      if (tp != null) {
        final tpDiff = (tp - price).abs();
        _potentialProfit = tpDiff * lot * contractSize;
      } else {
        _potentialProfit = 0;
      }

      if (sl != null) {
        final slDiff = (price - sl).abs();
        _potentialLoss = slDiff * lot * contractSize;
      } else {
        _potentialLoss = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OCR İşlem Tanıma')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Resim Yükle'),
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Image.file(
                  _image!,
                  height: MediaQuery.of(context).size.height * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            if (_parsedData != null) ...[
              Text('Sembol: ${_parsedData!.symbol ?? 'Bulunamadı'}'),
              Text('Fiyat: ${_parsedData!.price ?? 'Bulunamadı'}'),
              TextField(
                controller: _tpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'TP (Kâr Al)'),
              ),
              TextField(
                controller: _slController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'SL (Zararı Durdur)'),
              ),
              TextField(
                controller: _lotController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Lot'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _calculatePnL,
                child: Text('Kar / Zarar Hesapla'),
              ),
              if (_potentialProfit != null && _potentialLoss != null) ...[
                SizedBox(height: 12),
                Text('Olası Kar: ${_potentialProfit!.toStringAsFixed(2)}'),
                Text('Olası Zarar: ${_potentialLoss!.toStringAsFixed(2)}'),
              ]
            ] else ...[
              SizedBox(height: 20),
              Text('Henüz veri analiz edilmedi'),
            ]
          ],
        ),
      ),
    );
  }
}
