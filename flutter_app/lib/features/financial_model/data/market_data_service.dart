class CropFinancialData {
  final double marketPricePerQuintal; // Average market price in INR
  final double cultivationCostPerAcre; // Estimated cost of cultivation per acre in INR

  const CropFinancialData({
    required this.marketPricePerQuintal,
    required this.cultivationCostPerAcre,
  });
}

class MarketDataService {
  // Static mock data for common crops (approximate Indian market averages)
  static final Map<String, CropFinancialData> _marketData = {
    'Onion': const CropFinancialData(marketPricePerQuintal: 2500, cultivationCostPerAcre: 40000),
    'Tomato': const CropFinancialData(marketPricePerQuintal: 1800, cultivationCostPerAcre: 35000),
    'Potato': const CropFinancialData(marketPricePerQuintal: 1200, cultivationCostPerAcre: 30000),
    'Rice': const CropFinancialData(marketPricePerQuintal: 2200, cultivationCostPerAcre: 25000),
    'Wheat': const CropFinancialData(marketPricePerQuintal: 2125, cultivationCostPerAcre: 15000), // MSP Reference
    'Maize': const CropFinancialData(marketPricePerQuintal: 2090, cultivationCostPerAcre: 20000), // MSP Reference
    'Cotton': const CropFinancialData(marketPricePerQuintal: 6600, cultivationCostPerAcre: 35000), // MSP Reference
    'Sugarcane': const CropFinancialData(marketPricePerQuintal: 315, cultivationCostPerAcre: 50000), // FRP Reference (per quintal is low, yield is high)
  };

  static CropFinancialData getFinancialData(String cropName) {
    return _marketData[cropName] ?? 
           const CropFinancialData(marketPricePerQuintal: 2000, cultivationCostPerAcre: 30000); // Default fallback
  }
}
