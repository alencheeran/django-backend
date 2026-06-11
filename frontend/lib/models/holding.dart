class HoldingModel {
  final String stockSymbol;
  final int quantity;
  final double averageBuyPrice;
  final double currentPrice;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercentage;

  HoldingModel({
    required this.stockSymbol,
    required this.quantity,
    required this.averageBuyPrice,
    required this.currentPrice,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercentage,
  });

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    return HoldingModel(
      stockSymbol: json['stock_symbol'] as String,
      quantity: json['quantity'] as int,
      averageBuyPrice: double.tryParse(json['average_buy_price']?.toString() ?? '0') ?? 0.0,
      currentPrice: double.tryParse(json['current_price']?.toString() ?? '0') ?? 0.0,
      currentValue: double.tryParse(json['current_value']?.toString() ?? '0') ?? 0.0,
      profitLoss: double.tryParse(json['profit_loss']?.toString() ?? '0') ?? 0.0,
      profitLossPercentage: double.tryParse(json['profit_loss_percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}
