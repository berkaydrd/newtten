import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_newtten/utilities/firestore_service.dart' as FirestoreService;
import 'package:flutter_application_newtten/widgets/portfolio_donut_chart_with_pp_widget.dart';

class EditPortfolioPage extends StatefulWidget {
  final String username;
  final List<Map<String, dynamic>>? initialPortfolio; 
  final String? profileImageUrl; 

  const EditPortfolioPage({
    super.key, 
    required this.username,
    this.initialPortfolio,
    this.profileImageUrl, 
  });

  @override
  State<EditPortfolioPage> createState() => _EditPortfolioPageState();
}

class _EditPortfolioPageState extends State<EditPortfolioPage> {
  final _symbolController = TextEditingController();
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isSellMode = false;
  Color _selectedColor = Colors.blue; 
  
  final List<Color> _colorPalette = [
    Colors.red, Colors.blue, Colors.green, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.amber,
    Colors.indigo, Colors.brown, Colors.cyan, Colors.deepOrange,
    Colors.lime, Colors.blueGrey, Colors.black, Colors.grey
  ];

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bir Renk Seçin'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10, runSpacing: 10,
              children: _colorPalette.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.of(context).pop();
                  },
                  child: Container(width: 50, height: 50, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1))),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _handleTransaction(List<Map<String, dynamic>> currentPortfolio) async {
    if (_symbolController.text.isEmpty || _sharesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen sembol ve adet girin.')));
      return;
    }

    String symbol = _symbolController.text.toUpperCase().trim();
    double inputShares = double.tryParse(_sharesController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 1.0;

    var existingStock = currentPortfolio.firstWhere(
      (element) => element['symbol'] == symbol, 
      orElse: () => {},
    );

    double currentShares = 0;
    if (existingStock.isNotEmpty) {
      currentShares = double.tryParse(existingStock['shares'].toString()) ?? 0;
    }

    if (_isSellMode) {
      if (existingStock.isEmpty || currentShares <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portföyünüzde satacak bu hisse yok!')));
        return;
      }
      if (inputShares > currentShares) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elinizde bu kadar hisse yok!')));
        return;
      }
      double newShares = currentShares - inputShares;
      if (newShares <= 0) {
        await FirestoreService.FirestoreService.deleteStockFromPortfolio(widget.username, symbol);
      } else {
        final stockData = {
          'symbol': symbol,
          'shares': newShares,
          'purchase_price': existingStock['purchase_price'], 
          'current_price': price,
          'color': existingStock['color'],
        };
        await FirestoreService.FirestoreService.addStockToPortfolio(widget.username, stockData);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$symbol Satışı Başarılı!')));
    } else {
      double newShares = currentShares + inputShares; 
      final stockData = {
        'symbol': symbol,
        'shares': newShares,
        'purchase_price': price, 
        'current_price': price,
        'color': existingStock.isNotEmpty ? existingStock['color'] : _selectedColor.value,
      };
      await FirestoreService.FirestoreService.addStockToPortfolio(widget.username, stockData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alış İşlemi Başarılı!')));
    }

    _symbolController.clear();
    _sharesController.clear();
    _priceController.clear();
    setState(() => _selectedColor = Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portföyü Düzenle'), centerTitle: true),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                initialData: widget.initialPortfolio, 
                stream: FirestoreService.FirestoreService.getPortfolioStream(widget.username),
                builder: (context, snapshot) {
                  final portfolioData = snapshot.hasData ? snapshot.data! : <Map<String, dynamic>>[];
                  
                  return Column(
                    children: [
                      // --- DÜZELTME BURADA BAŞLIYOR ---
                      // İç içe Hero yerine STACK kullanıyoruz.
                      // Stack: Üst üste koyma demek.
                      Stack(
                        alignment: Alignment.center, // Her şeyi ortala
                        children: [
                          // KATMAN 1: Grafik (Altta)
                          Hero(
                            tag: 'portfolio_chart_hero',
                            child: Material(
                              color: Colors.transparent, 
                              child: PortfolioDonutChart(
                                portfolio: portfolioData,
                                // Grafiğin içine boş widget veriyoruz çünkü resmi üstüne biz koyacağız
                                centerWidget: const SizedBox.shrink(), 
                              ),
                            ),
                          ),

                          // KATMAN 2: Profil Resmi (Üstte)
                          // Bu arkadaş 'profile_image_hero' etiketiyle uçarak buraya konacak.
                          Hero(
                            tag: 'profile_image_hero',
                            child: Material(
                              color: Colors.transparent,
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: widget.profileImageUrl != null 
                                  ? CachedNetworkImageProvider(widget.profileImageUrl!) 
                                  : null,
                                child: widget.profileImageUrl == null 
                                  ? Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?', style: const TextStyle(fontSize: 30, color: Colors.black, fontWeight: FontWeight.bold)) 
                                  : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // --- DÜZELTME BİTTİ ---
                      
                      const SizedBox(height: 30),

                      // --- İŞLEM KARTI ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          children: [
                            Container(height: 45, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25)), child: Stack(children: [AnimatedAlign(duration: const Duration(milliseconds: 250), curve: Curves.decelerate, alignment: _isSellMode ? Alignment.centerRight : Alignment.centerLeft, child: FractionallySizedBox(widthFactor: 0.5, child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)])))), Row(children: [Expanded(child: GestureDetector(onTap: () => setState(() => _isSellMode = false), child: Container(color: Colors.transparent, alignment: Alignment.center, child: Text("ALIŞ", style: TextStyle(fontWeight: FontWeight.bold, color: !_isSellMode ? Colors.green[700] : Colors.grey))))), Expanded(child: GestureDetector(onTap: () => setState(() => _isSellMode = true), child: Container(color: Colors.transparent, alignment: Alignment.center, child: Text("SATIŞ", style: TextStyle(fontWeight: FontWeight.bold, color: _isSellMode ? Colors.red[700] : Colors.grey)))))])])),
                            const SizedBox(height: 20),
                            TextField(controller: _symbolController, decoration: const InputDecoration(labelText: 'Hisse Sembolü', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), textCapitalization: TextCapitalization.characters),
                            const SizedBox(height: 15),
                            Row(children: [Expanded(child: TextField(controller: _sharesController, decoration: const InputDecoration(labelText: 'Adet', border: OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width: 15), Expanded(child: TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Fiyat', border: OutlineInputBorder(), hintText: '1.0'), keyboardType: TextInputType.number))]),
                            AnimatedSize(duration: const Duration(milliseconds: 300), child: _isSellMode ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 15), child: GestureDetector(onTap: _openColorPicker, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Grafik Rengi:", style: TextStyle(fontSize: 16)), Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: _selectedColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))), const SizedBox(width: 10), const Icon(Icons.arrow_drop_down)])]))))),
                            const SizedBox(height: 20),
                            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => _handleTransaction(portfolioData), style: ElevatedButton.styleFrom(backgroundColor: _isSellMode ? Colors.red[700] : Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(_isSellMode ? 'SATIŞ YAP' : 'PORTFÖYE EKLE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}