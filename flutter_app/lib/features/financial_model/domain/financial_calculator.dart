class FinancialMetrics {
  final double grossRevenue;
  final double totalCost;
  final double netProfit;
  final double roiPercentage;

  FinancialMetrics({
    required this.grossRevenue,
    required this.totalCost,
    required this.netProfit,
    required this.roiPercentage,
  });
}

class FinancialCalculator {
  static FinancialMetrics calculateMetrics({
    required double predictedYieldPerAcre, // Quintals per acre
    required double fieldAreaAcres,
    required double marketPricePerQuintal,
    required double costPerAcre,
  }) {
    final double grossRevenue = predictedYieldPerAcre * fieldAreaAcres * marketPricePerQuintal;
    final double totalCost = costPerAcre * fieldAreaAcres;
    final double netProfit = grossRevenue - totalCost;
    
    double roi = 0.0;
    if (totalCost > 0) {
      roi = (netProfit / totalCost) * 100;
    }

    return FinancialMetrics(
      grossRevenue: grossRevenue,
      totalCost: totalCost,
      netProfit: netProfit,
      roiPercentage: roi,
    );
  }
}
