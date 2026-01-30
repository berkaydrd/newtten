import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_newtten/widgets/period_button_widget.dart';

final List<FlSpot> defaultChartData = const [
  FlSpot(0, 3), 
  FlSpot(1, 4), 
  FlSpot(2, 3.5),
  FlSpot(3, 5),
  FlSpot(4, 4.5),
  FlSpot(5, 6),
  FlSpot(6, 7.2),
];

class ChartContainer extends StatefulWidget {
  const ChartContainer({super.key, required List<Map<String, dynamic>> portfolio});

  @override
  State<ChartContainer> createState() => _ChartContainerState();
}

class _ChartContainerState extends State<ChartContainer> {
  ChartPeriod _selectedPeriod = ChartPeriod.all;
  List<FlSpot> _chartData = defaultChartData;

  void _loadChartData(ChartPeriod period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      // Buraya periyoda göre veriyi çekme/oluşturma mantığı gelir.
      _chartData = defaultChartData; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40.0, right: 20.0),
          child: SizedBox(
            height: 140,
            child: EarningsChartWidget(chartData: _chartData), 
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            children: [
              PeriodButton(
                period: ChartPeriod.all,
                label: 'tümü',
                isSelected: _selectedPeriod == ChartPeriod.all,
                onSelected: _loadChartData,
              ),
              PeriodButton(
                period: ChartPeriod.daily,
                label: '1G',
                isSelected: _selectedPeriod == ChartPeriod.daily,
                onSelected: _loadChartData,
              ),
              PeriodButton(
                period: ChartPeriod.weekly,
                label: '1H',
                isSelected: _selectedPeriod == ChartPeriod.weekly,
                onSelected: _loadChartData,
              ),
              PeriodButton(
                period: ChartPeriod.monthly,
                label: '1A',
                isSelected: _selectedPeriod == ChartPeriod.monthly,
                onSelected: _loadChartData,
              ),
              PeriodButton(
                period: ChartPeriod.sixMonthly,
                label: '6A',
                isSelected: _selectedPeriod == ChartPeriod.sixMonthly,
                onSelected: _loadChartData,
              ),
              PeriodButton(
                period: ChartPeriod.yearly,
                label: '1Y',
                isSelected: _selectedPeriod == ChartPeriod.yearly,
                onSelected: _loadChartData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EarningsChartWidget extends StatelessWidget {
  final List<FlSpot> chartData;
  double get latestEarnings {
    if (chartData.isEmpty) return 0.0;
    return chartData.last.y;
  }
  
  const EarningsChartWidget({
    super.key,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    const double leftTitlesReservedSize = 5.0;
    const double plotPadding = 5.0;
    
    return Stack(
      children: [
        LineChart(
          LineChartData(
            minY: 0,
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, 
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: chartData, 
                //isCurved: true,
                color: const Color.fromARGB(255, 0, 0, 0),
                barWidth: 2.0,
                dotData: FlDotData(show: true, checkToShowDot: (spot, barData) => spot.x == barData.spots.last.x),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(90, 0, 0, 0),
                      const Color.fromARGB(0, 0, 0, 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            gridData: const FlGridData(show: false), 
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 0.5),
            ),
          ),
        ),
        
        // Etiket (Positioned)
        Positioned(
          left: leftTitlesReservedSize,
          top: plotPadding, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              '%${latestEarnings.toStringAsFixed(1)}', 
                style: const TextStyle(
                  fontSize: 12, 
                  color: Colors.black, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}