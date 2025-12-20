import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_newtten/utilities/firestore_service.dart';
import 'package:flutter_application_newtten/views/edit_portfolio_view.dart';
import 'package:flutter_application_newtten/widgets/earnings_chart_widget.dart';
import 'package:flutter_application_newtten/widgets/pie_chart_widget.dart';
import 'package:flutter_application_newtten/widgets/portfolio_list_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Yükleniyor...';
  String? _profileImagePath;
  bool _showPieChart = true;
  int _selectedIndex = 0;

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
      if (mounted) {
        setState(() {
          _username = 'Giriş Yapılmadı';
        });
      }
      return;
    }
    final fetchedUsername = await FirestoreService.getUsername(user.uid);
    if (mounted) {
      setState(() {
        _username = fetchedUsername ?? 'Misafir';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Color.fromARGB(190, 0, 0, 0),
        shadowColor: Colors.black, 
        elevation: 0.1,
        leadingWidth: 60.0,
        leading: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Image.asset(
            'assets/images/Logo.png',
            width: 65.0,
            height: 65.0,
            fit: BoxFit.fill,
          )
        ),
        title: Text(
          _username, 
          style: const TextStyle(
            fontWeight: FontWeight.w500
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: (){},
            icon: const Icon(Icons.settings_suggest_outlined),
          )
        ],
      ),
      body: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.only(
                  top: 40.0,
                  left: 20.0,
                ),
                child: Column(
                  children: [
                    _buildProfileImage(),//             ProfileImage
                    const SizedBox(height: 5.0),
                    const Text(//                       Followers
                      '234 Takipçi',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const Text(//                       Subscribers
                      '5 Abone',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    SizedBox(height: 40.0),
                  ],              
                ),
              ),
              const SizedBox(width: 20.0),
              Expanded(//                               PieChart / LineChart
                child: Padding(
                  padding: const EdgeInsets.only(top:0.0, right: 10.0,),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _showPieChart 
                      ? PortfolioPieChart(
                          key: const ValueKey('Pie'),
                          portfolio: _portfolio
                        )
                      : ChartContainer(
                          key: const ValueKey('line'),
                          portfolio: _portfolio,
                        ),
                  ),
                ),
              ),
            ],
          ),
          TextButton(//                                 EditPortfolio
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPortfolioPage(username: _username.toLowerCase(),) 
                )
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Portföyü Düzenle',
              style: TextStyle(
                fontSize: 13.0,
              ),
            )
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Color.fromARGB(60, 0, 0, 0),
          ),
          Expanded(//                                   PortfolioList
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _username == 'Yükleniyor...'
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirestoreService.getPortfolioStream(_username),
                      builder: (context, snapshot){
                        if (snapshot.hasError){
                          return Center(child: Text("Hata: ${snapshot.error}"));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting){
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty){
                          return const Center(
                            child: Text(
                              'Henüz Portföyün Boş',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        final dbPortfolio = snapshot.data!;
                        return PortfolioListWidget(portfolio: dbPortfolio);
                      },
                    )
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(//                     BottomNavigationBar
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.grey,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if(index == 2){
              setState(() {
                _showPieChart = !_showPieChart;
              });
            }
            else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              backgroundColor: Colors.black
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(_showPieChart ? Icons.line_axis : Icons.pie_chart),
              label: _showPieChart ? 'Grafik' : 'Grafik', 
            ),
          ],

        ),
      ),
    );
  }
  Widget _buildProfileImage() {
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(_profileImagePath!)),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Color.fromARGB(30, 0, 0, 0),
        radius: 50,
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.black,
        ),
      );
    }
  }
}