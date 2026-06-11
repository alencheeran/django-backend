class StockModel {
  final String symbol;
  final String name;
  final double? currentPrice;
  final double? change;
  final double? changePercentage;
  final double? high;
  final double? low;
  final int? volume;

  StockModel({
    required this.symbol,
    required this.name,
    this.currentPrice,
    this.change,
    this.changePercentage,
    this.high,
    this.low,
    this.volume,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currentPrice: double.tryParse(json['current_price']?.toString() ?? ''),
      change: double.tryParse(json['change']?.toString() ?? ''),
      changePercentage: double.tryParse(json['change_percentage']?.toString() ?? ''),
      high: double.tryParse(json['high']?.toString() ?? ''),
      low: double.tryParse(json['low']?.toString() ?? ''),
      volume: json['volume'] as int?,
    );
  }

  StockModel copyWith({
    double? currentPrice,
    double? change,
    double? changePercentage,
    double? high,
    double? low,
    int? volume,
  }) {
    return StockModel(
      symbol: symbol,
      name: name,
      currentPrice: currentPrice ?? this.currentPrice,
      change: change ?? this.change,
      changePercentage: changePercentage ?? this.changePercentage,
      high: high ?? this.high,
      low: low ?? this.low,
      volume: volume ?? this.volume,
    );
  }
}
