import 'package:flutter/material.dart';

typedef StockPortfolio = List<Map<String, dynamic>>;

class PortfolioListWidget extends StatelessWidget {

  final StockPortfolio portfolio;

  const PortfolioListWidget({
    super.key,
    required this.portfolio,
  });

  double calculateProfitLoss(double shares, double purchasePrice, double currentPrice) {
    return (currentPrice - purchasePrice) * shares;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: portfolio.length,
      itemBuilder: (context, index) {
        final stock = portfolio[index];
        final shares = (stock['shares'] ?? 0).toDouble();
        final purchasePrice = (stock['purchase_price'] ?? 0).toDouble();
        final currentPrice = (stock['current_price'] ?? 0).toDouble();
        final profitLoss = calculateProfitLoss(
          shares,
          purchasePrice,
          currentPrice,
        );
        final isProfit = profitLoss >= 0;
        final profitLossColor = isProfit ? Colors.green.shade700 : Colors.red.shade700;

        return ExpansionTile(
          visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          title: Text(
            stock['symbol']!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            'Adet: ${stock['shares']} | Güncel: \$${stock['current_price']}',
            style: TextStyle(
              fontSize: 10
            ),
          ),

          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 5, right: 8, left: 8),
              child: Column(
                children: [
                  _buildDetailRow('Alış Fiyatı:', '\$${stock['purchase_price']}'),
                  _buildDetailRow(
                    'Kar / Zarar:', 
                    '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                    valueColor: profitLossColor
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: valueColor ?? Colors.black,
            fontSize: 10,
          )
        ),
      ],
    );
  }
}