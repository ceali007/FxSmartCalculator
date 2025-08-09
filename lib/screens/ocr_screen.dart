 import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/calculation_result.dart';
import '../models/parsed_trade_data.dart';
import '../models/symbol_model.dart';
import '../services/calculation_service.dart';
import '../services/symbol_service.dart';
import '../utils/ocr_parser.dart';
import '../utils/parser_helper.dart';
import '../utils/text_parser_helper.dart';

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
  List<SymbolModel> _symbolList = [];
  final ScrollController _scrollController = ScrollController();

  bool _showRiskControls = false;
  double _riskPercentage = 1.0;
  final TextEditingController _balanceController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadSymbols();
  }

  Future<void> _loadSymbols() async {
    final symbols = await SymbolService().getAllSymbols();
    setState(() {
      _symbolList = symbols;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }
  void _handleCalculate() async {
    final lot = double.tryParse(_lotController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final tp = double.tryParse(_tpController.text);
    final sl = double.tryParse(_slController.text);

    if (_symbolModel == null || lot == 0 || price == 0) {
      print("Eksik veri: Sembol, lot veya fiyat eksik.");
      return;
    }

    try {
      final result = await CalculationService.calculatePnL(
        symbol: _symbolModel!,
        price: price,
        lot: lot,
        tp: tp,
        sl: sl,
      );

      setState(() {
        _profit = result.profit;
        _loss = result.loss;
      });

      _showPnLDialog(result);
    } catch (e) {
      print("Hesaplama sırasında hata: $e");
    }
  }




  void _showPnLDialog(CalculationResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Tahmini Kar/Zarar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.profit != null)
                Text('Tahmini Kar: ${result.profit!.toStringAsFixed(2)} \$',
                    style: TextStyle(color: Colors.green)),
              if (result.loss != null)
                Text('Tahmini Zarar: ${result.loss!.toStringAsFixed(2)} \$',
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
      items: _symbolList.map((symbol) {
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

  void _showImagePopup() {
    if (_image == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          insetPadding: EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Image.file(
              _image!,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {Color? color}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: 14, color: color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color ?? Colors.black, fontSize: 13),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade400,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  void _showTextParseDialog(BuildContext context) {
    final TextEditingController _textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İşlem Metni Yapıştır'),
        content: TextField(
          controller: _textController,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'EURUSD SEL\nGIRIS : 1.16772\nSL: 1.17534\nTP: 1.15887',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Kapat
            },
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final parsed = TextParserHelper.parseText(_textController.text);

              // Kontrolleri doldur
              _priceController.text = parsed['price'] ?? '';
              _tpController.text = parsed['tp'] ?? '';
              _slController.text = parsed['sl'] ?? '';

              final parsedSymbol = parsed['symbol'] ?? '';
              if (parsedSymbol.isNotEmpty) {
                final matched = _symbolList.firstWhere(
                      (s) =>
                  s.symbol == parsedSymbol ||
                      s.alternativeCodes.contains(parsedSymbol),
                  orElse: () => _symbolList.first,
                );
                setState(() {
                  _symbolModel = matched;
                });
              }

              Navigator.of(context).pop(); // Kapat
            },
            child: Text('Parse Et'),
          ),
        ],
      ),
    );
  }

  void _calculateLotForRisk() {
    final balance = double.tryParse(_balanceController.text);
    final price = double.tryParse(_priceController.text);
    final sl = double.tryParse(_slController.text);

    if (_symbolModel == null || balance == null || price == null || sl == null) {
      return;
    }

    final lot = CalculationService.calculateLotByRiskRatio(
      price: price,
      sl: sl,
      balance: balance,
      riskPercentage: _riskPercentage,
      contractSize: _symbolModel!.contractSize.toDouble(),
    );

    if (lot != null) {
      setState(() {
        _lotController.text = lot.toStringAsFixed(2);
      });
    }
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _getImageAndParseText,
                  child: Text('Resim Yükle'),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: GestureDetector(
                      onTap: _showImagePopup,
                      child: Image.file(
                        _image!,
                        height: MediaQuery.of(context).size.height * 0.35,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showTextParseDialog(context),
                  child: Text('Text Parse'),
                ),
                SizedBox(height: 10),
                _buildSymbolDropdown(),
                SizedBox(height: 8),
                _buildTextField(_priceController, 'Fiyat'),
                SizedBox(height: 8),
                _buildTextField(_tpController, 'TP (Kar Al)', color: Colors.green[800]),
                SizedBox(height: 8),
                _buildTextField(_slController, 'SL (Zarar Durdur)', color: Colors.red[800]),
                SizedBox(height: 8),
                CheckboxListTile(
                  title: Text('Kayıp Oranı'),
                  value: _showRiskControls,
                  onChanged: (value) {
                    setState(() {
                      _showRiskControls = value!;
                    });
                  },
                ),
                if (_showRiskControls) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: _balanceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Bakiye (USD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Text('Zarar Oranı: ${_riskPercentage.toStringAsFixed(1)} %'),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_riskPercentage > 1.0) _riskPercentage -= 0.5;
                            _calculateLotForRisk();
                          });
                        },
                      ),
                      Expanded(
                        child: Slider(
                          value: _riskPercentage,
                          min: 1.0,
                          max: 10.0,
                          divisions: 18,
                          label: '${_riskPercentage.toStringAsFixed(1)}%',
                          onChanged: (value) {
                            setState(() {
                              _riskPercentage = value;
                              _calculateLotForRisk();
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            if (_riskPercentage < 10.0) _riskPercentage += 0.5;
                            _calculateLotForRisk();
                          });
                        },
                      ),
                    ],
                  )
                ],
                SizedBox(height: 8),
                _buildTextField(_lotController, 'Lot Miktarı'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _handleCalculate,
                  child: Text('Hesapla'),
                ),
                SizedBox(height: 32),
                if (_parsedData == null && _image == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text('Resim yüklemeden manuel giriş yapabilirsiniz.'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
