import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/parsed_trade_data.dart';
import '../models/symbol_model.dart';
import '../services/symbol_service.dart';
import '../utils/ocr_parser.dart';
import '../utils/parser_helper.dart';

class OcrScreen extends StatefulWidget {
  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _image;
  ParsedTradeData? _parsedData;
  final picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final TextEditingController _lotController = TextEditingController();
  final TextEditingController _tpController = TextEditingController();
  final TextEditingController _slController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  SymbolModel? _symbolModel;
  double? _profit;
  double? _loss;
  List<SymbolModel> _symbols = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSymbols();
  }

  Future<void> _loadSymbols() async {
    final symbols = await SymbolService().getAllSymbols();
    setState(() {
      _symbols = symbols;
    });
  }

  Future<void> _getImageAndParseText() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final parsed = OCRParser.parse(recognizedText);
    final rawSymbol = parsed.symbol;

    final symbol = rawSymbol != null
        ? await SymbolService().getSymbol(ParserHelper.cleanSymbol(rawSymbol))
        : null;

    setState(() {
      _image = File(pickedFile.path);
      _parsedData = parsed;
      _symbolModel = symbol;
      _tpController.text = parsed.tp?.toString() ?? '';
      _slController.text = parsed.sl?.toString() ?? '';
      _priceController.text = parsed.price?.toString() ?? '';
    });

    await Future.delayed(Duration(milliseconds: 300));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _calculatePnL() {
    final lot = double.tryParse(_lotController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final tp = double.tryParse(_tpController.text);
    final sl = double.tryParse(_slController.text);

    if (_symbolModel == null || lot == 0 || price == 0) return;

    final contractSize = _symbolModel!.contractSize;

    double? profit;
    double? loss;

    if (tp != null && tp > 0) {
      final isBuy = tp > price;
      final diff = (tp - price).abs();
      final value = lot * contractSize * diff;
      if (isBuy) {
        profit = value;
      } else {
        loss = value;
      }
    }

    if (sl != null && sl > 0) {
      final isBuy = sl < price;
      final diff = (price - sl).abs();
      final value = lot * contractSize * diff;
      if (isBuy) {
        loss = value;
      } else {
        profit = value;
      }
    }

    setState(() {
      _profit = profit;
      _loss = loss;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Tahmini Kar/Zarar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_profit != null)
                Text('Tahmini Kar: ${_profit!.toStringAsFixed(2)} \$',
                    style: TextStyle(color: Colors.green)),
              if (_loss != null)
                Text('Tahmini Zarar: ${_loss!.toStringAsFixed(2)} \$',
                    style: TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Kapat"),
            )
          ],
        );
      },
    );
  }

  Widget _buildSymbolDropdown() {
    return DropdownButtonFormField<SymbolModel>(
      value: _symbolModel,
      decoration: InputDecoration(
        labelText: 'Sembol Seç',
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade400, // Daha açık gri
            width: 1.0,
          ),
        ),
      ),
      items: _symbols.map((symbol) {
        return DropdownMenuItem<SymbolModel>(
          value: symbol,
          child: Text(symbol.symbol, style: TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _symbolModel = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SmartCalculator',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _getImageAndParseText,
              child: Text('Resim Yükle'),
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Image.file(
                  _image!,
                  height: MediaQuery.of(context).size.height * 0.35,
                  fit: BoxFit.contain,
                ),
              ),
            SizedBox(height: 10),
            _buildSymbolDropdown(),
            SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Fiyat',
                labelStyle: TextStyle(fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade400, // Daha açık gri
                    width: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _tpController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14, color: Colors.green[800]),
              decoration: InputDecoration(
                labelText: 'TP (Kar Al)',
                labelStyle: TextStyle(color: Colors.green[800], fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade400, // Daha açık gri
                    width: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _slController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14, color: Colors.red[800]),
              decoration: InputDecoration(
                labelText: 'SL (Zarar Durdur)',
                labelStyle: TextStyle(color: Colors.red[800], fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade400, // Daha açık gri
                    width: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _lotController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Lot Miktarı',
                labelStyle: TextStyle(fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.shade400, // Daha açık gri
                    width: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _calculatePnL,
              child: Text('Hesapla'),
            ),
            if (_parsedData == null && _image == null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Resim yüklemeden manuel giriş yapabilirsiniz.'),
              ),
          ],
        ),
      ),
    );
  }
}
