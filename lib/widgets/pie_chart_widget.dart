import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PortfolioPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> portfolio;

  const PortfolioPieChart({super.key, required this.portfolio});

  @override
  State<PortfolioPieChart> createState() => _PortfolioPieChartState();
}

class _PortfolioPieChartState extends State<PortfolioPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1, // Kare şeklinde kalmasını sağlar
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 1.0, // Dilimler arası boşluk
                centerSpaceRadius: 4.0, // Ortadaki boşluk (Donut şekli için)
                sections: _showingSections(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Verileri PieChartSectionData'ya dönüştüren fonksiyon
  List<PieChartSectionData> _showingSections() {
    // Toplam portföy değerini hesapla
    double totalValue = 0;
    for (var item in widget.portfolio) {
      totalValue += (item['shares'] as num) * (item['current_price'] as num);
    }

    return List.generate(widget.portfolio.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 15.0 : 12.0;
      final radius = isTouched ? 95.0 : 85.0; // Tıklanınca büyüme efekti

      final item = widget.portfolio[i];
      final num value = (item['shares'] as num) * (item['current_price'] as num);
      final double percentage = (value / totalValue) * 100;

      return PieChartSectionData(
        color: _getColor(i),
        //value: value,
        title: '${percentage.toStringAsFixed(0)}%\n${item['symbol']}', // Yüzdeyi göster
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  // Renk paleti (Sırasıyla atanır)
  Color _getColor(int index) {
    const List<Color> colors = [
      Colors.black, // 1. Eleman (AAPL)
      Color(0xFF3B3B3B), // 2. Eleman (MSFT) - Koyu Gri
      Color(0xFF757575), // 3. Eleman (GOOGL) - Açık Gri
      Colors.blueGrey,
      Colors.grey,
    ];
    return colors[index % colors.length];
  }
}
