class TransactionModel {
  final int id;
  final String stockSymbol;
  final String transactionType; // BUY or SELL
  final int quantity;
  final double price;
  final double totalValue;
  final String status;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.stockSymbol,
    required this.transactionType,
    required this.quantity,
    required this.price,
    required this.totalValue,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      stockSymbol: json['stock_symbol'] as String,
      transactionType: json['transaction_type'] as String,
      quantity: json['quantity'] as int,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
