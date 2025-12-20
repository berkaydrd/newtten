import 'package:flutter/material.dart';
import 'package:flutter_application_newtten/utilities/firestore_service.dart' as FirestoreService;

class EditPortfolioPage extends StatefulWidget {
  final String username;
  const EditPortfolioPage({super.key, required this.username});

  @override
  State<EditPortfolioPage> createState() => _EditPortfolioPageState();
}

class _EditPortfolioPageState extends State<EditPortfolioPage> {
  final _symbolController = TextEditingController();
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();

  void _saveStock() async {
    if (_symbolController.text.isNotEmpty && _sharesController.text.isNotEmpty) {
      final stockData = {
        'symbol': _symbolController.text.toUpperCase(),
        'shares': double.tryParse(_sharesController.text) ?? 0,
        'purchase_price': double.tryParse(_priceController.text) ?? 0,
        'current_price': double.tryParse(_priceController.text) ?? 0,
      };

      await FirestoreService.FirestoreService.addStockToPortfolio(widget.username, stockData);
      _symbolController.clear();
      _sharesController.clear();
      _priceController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hisse başarıyla eklendi!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portföyü Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _symbolController, decoration: const InputDecoration(labelText: 'Hisse Sembolü (Örn: THYAO)')),
            TextField(controller: _sharesController, decoration: const InputDecoration(labelText: 'Adet'), keyboardType: TextInputType.number),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Alış Fiyatı'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveStock,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              child: const Text('Hisse Ekle'),
            ),
            const Divider(height: 40),
            const Text('Mevcut Hisseleriniz', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}