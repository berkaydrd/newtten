import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_newtten/utilities/firestore_service.dart';
import 'package:flutter_application_newtten/views/edit_portfolio_view.dart';
import 'package:flutter_application_newtten/widgets/earnings_chart_widget.dart';
import 'package:flutter_application_newtten/widgets/pie_chart_widget.dart';
import 'package:flutter_application_newtten/widgets/portfolio_list_widget.dart';
import 'package:flutter_application_newtten/widgets/profile_image_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Stream<List<Map<String, dynamic>>>? _portfolioStream;
  String _username = 'Yükleniyor...';
  String? _profileImagePath;  
  bool _showPieChart = true;
  int _selectedIndex = 0;

  // Veriyi burada tutuyoruz ki sayfalar arası geçişte kaybolmasın
  List<Map<String, dynamic>> _currentPortfolioData = [];

  final List<Map<String, dynamic>> _portfolio = [
    {'symbol': 'AAPL', 'shares': 5, 'purchase_price': 150.0, 'current_price': 175.50},
    {'symbol': 'MSFT', 'shares': 10, 'purchase_price': 250.0, 'current_price': 300.00},
    {'symbol': 'GOOGL', 'shares': 2, 'purchase_price': 1000.0, 'current_price': 300.00},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _username = 'Giriş Yapılmadı');
      return;
    }
    try {
      final fetchedUsername = await FirestoreService.getUsername(user.uid);
      final validUsername = fetchedUsername ?? 'Misafir';
      final fetchedImagePath = await FirestoreService.getProfileImagePath(validUsername);
      
      // Broadcast stream yapıyoruz ki birden fazla yerde dinlersek hata vermesin
      final newStream = FirestoreService.getPortfolioStream(validUsername).asBroadcastStream();

      if (mounted) {
        setState(() {
          _profileImagePath = fetchedImagePath;
          _username = validUsername;
          _portfolioStream = newStream; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _username = 'Hata oluştu');
      debugPrint("Kullanıcı yüklenirken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(190, 0, 0, 0),
        shadowColor: Colors.black, 
        elevation: 0.1,
        leadingWidth: 60.0,
        leading: Padding(padding: const EdgeInsets.all(1.0), child: Image.asset('assets/images/Logo.png', width: 65.0, height: 65.0, fit: BoxFit.fill)),
        title: Text(_username, style: const TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
        actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.settings_suggest_outlined))],
      ),
      
      // --- DÜZELTME 1: TEK BİR STREAMBUILDER ---
      // Sayfanın en tepesine koyuyoruz. Veriyi bir kere çekiyor, aşağıya dağıtıyor.
      // Böylece Hero animasyonu sırasında tekrar tekrar veri çekmeye çalışmıyor.
      body: _portfolioStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _portfolioStream,
              // initialData çok önemli: Eğer elimizde eski veri varsa onu kullan, 
              // böylece sayfa dönünce "Loading"e düşmez.
              initialData: _currentPortfolioData.isNotEmpty ? _currentPortfolioData : null,
              builder: (context, snapshot) {
                
                // Veriyi güncelleyelim
                if (snapshot.hasData) {
                  _currentPortfolioData = snapshot.data!;
                }

                // Veri setini belirle
                final displayData = snapshot.data ?? _currentPortfolioData;

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 40.0, left: 20.0),
                          child: Column(
                            children: [
                              // Profil Resmi
                              ProfileImageWidget(
                                username: _username,
                                initialImagePath: _profileImagePath,
                                onImageSelected: (newPath) => setState(() => _profileImagePath = newPath),
                              ),
                              const SizedBox(height: 5.0),
                              const Text('234 Takipçi', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500)),
                              const Text('5 Abone', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 40.0),
                            ],              
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 0.0, right: 10.0),
                            child: SizedBox(
                              height: 250, 
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: _showPieChart 
                                  // --- DÜZELTME 2: HERO DIŞARIDA, VERİ İÇERİDE ---
                                  // StreamBuilder artık burada değil, yukarıda.
                                  // Hero'ya direkt hazır 'displayData'yı veriyoruz.
                                  // Bu sayede animasyon sırasında veri yükleme derdi olmuyor, loop bitiyor.
                                  ? Hero(
                                      tag: 'portfolio_chart_hero',
                                      child: Material(
                                        color: Colors.transparent, 
                                        child: PortfolioPieChart(
                                          key: const ValueKey('Pie'),
                                          portfolioData: displayData, // <-- HAZIR VERİ
                                        ),
                                      ),
                                    )
                                  : ChartContainer(key: const ValueKey('line'), portfolio: _portfolio),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 900), 
                            reverseTransitionDuration: const Duration(milliseconds: 900),
                            pageBuilder: (context, animation, secondaryAnimation) => EditPortfolioPage(
                              username: _username.toLowerCase(),
                              initialPortfolio: _currentPortfolioData, // Veriyi elden veriyoruz
                              profileImageUrl: _profileImagePath,
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              var slideTween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut));
                              var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
                              return SlideTransition(
                                position: animation.drive(slideTween),
                                child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
                              );
                            },
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Portföyü Düzenle', style: TextStyle(fontSize: 13.0)),
                    ),
                    
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.5, color: Color.fromARGB(60, 0, 0, 0)),
                    
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            // Alt kısımdaki StreamBuilder'ı kaldırdık çünkü
                            // en tepedeki StreamBuilder veriyi zaten 'displayData' olarak sağlıyor.
                            child: PortfolioListWidget(portfolio: displayData),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.grey),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if(index == 2) setState(() => _showPieChart = !_showPieChart);
            else setState(() => _selectedIndex = index);
          },
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home', backgroundColor: Colors.black),
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(_showPieChart ? Icons.line_axis : Icons.pie_chart), label: 'Grafik'),
          ],
        ),
      ),
    );
  }
}
