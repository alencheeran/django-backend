import 'package:candlesticks/candlesticks.dart';

class CandleMapper {
  static Candle fromJson(Map<String, dynamic> json) {
    return Candle(
      date: DateTime.parse(json['date'] as String),
      high: double.tryParse(json['high']?.toString() ?? '0') ?? 0.0,
      low: double.tryParse(json['low']?.toString() ?? '0') ?? 0.0,
      open: double.tryParse(json['open']?.toString() ?? '0') ?? 0.0,
      close: double.tryParse(json['close']?.toString() ?? '0') ?? 0.0,
      volume: double.tryParse(json['volume']?.toString() ?? '0') ?? 0.0,
    );
  }
}
