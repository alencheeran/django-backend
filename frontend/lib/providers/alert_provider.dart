import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';
import 'market_provider.dart';

class StockAlert {
  final String symbol;
  final double targetPrice;
  final bool isAbove; // true if alert triggers when price >= targetPrice, false if <= targetPrice
  final bool isTriggered;

  StockAlert({
    required this.symbol,
    required this.targetPrice,
    required this.isAbove,
    this.isTriggered = false,
  });
  
  StockAlert copyWith({bool? isTriggered}) {
    return StockAlert(
      symbol: symbol,
      targetPrice: targetPrice,
      isAbove: isAbove,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'targetPrice': targetPrice,
    'isAbove': isAbove,
    'isTriggered': isTriggered,
  };

  factory StockAlert.fromJson(Map<String, dynamic> json) => StockAlert(
    symbol: json['symbol'] as String,
    targetPrice: (json['targetPrice'] as num).toDouble(),
    isAbove: json['isAbove'] as bool,
    isTriggered: json['isTriggered'] as bool? ?? false,
  );
}

class AlertNotifier extends StateNotifier<List<StockAlert>> {
  final SharedPreferences _prefs;

  AlertNotifier(this._prefs) : super([]) {
    _loadAlerts();
  }
  
  void _loadAlerts() {
    final raw = _prefs.getStringList('stock_alerts');
    if (raw != null) {
      try {
        state = raw.map((item) => StockAlert.fromJson(jsonDecode(item))).toList();
      } catch (_) {
        state = [];
      }
    }
  }
  
  void _saveAlerts() {
    final raw = state.map((item) => jsonEncode(item.toJson())).toList();
    _prefs.setStringList('stock_alerts', raw);
  }
  
  void addAlert(String symbol, double targetPrice, bool isAbove) {
    HapticFeedback.lightImpact();
    state = [
      ...state,
      StockAlert(symbol: symbol, targetPrice: targetPrice, isAbove: isAbove)
    ];
    _saveAlerts();
  }
  
  void removeAlert(int index) {
    HapticFeedback.lightImpact();
    state = List<StockAlert>.from(state)..removeAt(index);
    _saveAlerts();
  }
  
  void clearTriggered() {
    state = state.where((item) => !item.isTriggered).toList();
    _saveAlerts();
  }
  
  void checkAlerts(MarketState marketState, Function(StockAlert, double) onTrigger) {
    bool hasUpdates = false;
    final updated = state.map((alert) {
      if (alert.isTriggered) return alert;
      
      // Find matching stock update in list
      final stockIndex = marketState.stocks.indexWhere((s) => s.symbol == alert.symbol);
      if (stockIndex == -1) return alert;
      
      final stock = marketState.stocks[stockIndex];
      if (stock.currentPrice == null) return alert;
      
      final currentPrice = stock.currentPrice!;
      bool triggered = false;
      if (alert.isAbove && currentPrice >= alert.targetPrice) {
        triggered = true;
      } else if (!alert.isAbove && currentPrice <= alert.targetPrice) {
        triggered = true;
      }
      
      if (triggered) {
        hasUpdates = true;
        onTrigger(alert, currentPrice);
        return alert.copyWith(isTriggered: true);
      }
      return alert;
    }).toList();
    
    if (hasUpdates) {
      state = updated;
      _saveAlerts();
    }
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, List<StockAlert>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return AlertNotifier(prefs);
});
