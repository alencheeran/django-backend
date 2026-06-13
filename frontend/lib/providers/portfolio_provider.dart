import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class PortfolioHistoryModel {
  final String date;
  final double netWorth;

  PortfolioHistoryModel({required this.date, required this.netWorth});

  factory PortfolioHistoryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioHistoryModel(
      date: json['date'].toString(),
      netWorth: double.tryParse(json['net_worth'].toString()) ?? 0.0,
    );
  }
}

class PortfolioState {
  final double totalPortfolioValue;
  final double availableCash;
  final double investedAmount;
  final double oneDayReturn;
  final double oneDayReturnPercentage;
  final double totalReturn;
  final double totalReturnPercentage;
  final List<HoldingModel> holdings;
  final List<TransactionModel> transactions;
  final List<PortfolioHistoryModel> history;
  final bool isLoading;
  final String? error;

  PortfolioState({
    required this.totalPortfolioValue,
    required this.availableCash,
    required this.investedAmount,
    required this.oneDayReturn,
    required this.oneDayReturnPercentage,
    required this.totalReturn,
    required this.totalReturnPercentage,
    required this.holdings,
    required this.transactions,
    required this.history,
    required this.isLoading,
    this.error,
  });

  PortfolioState.initial()
      : totalPortfolioValue = 100000.0,
        availableCash = 100000.0,
        investedAmount = 0.0,
        oneDayReturn = 0.0,
        oneDayReturnPercentage = 0.0,
        totalReturn = 0.0,
        totalReturnPercentage = 0.0,
        holdings = [],
        transactions = [],
        history = [],
        isLoading = false,
        error = null;

  PortfolioState copyWith({
    double? totalPortfolioValue,
    double? availableCash,
    double? investedAmount,
    double? oneDayReturn,
    double? oneDayReturnPercentage,
    double? totalReturn,
    double? totalReturnPercentage,
    List<HoldingModel>? holdings,
    List<TransactionModel>? transactions,
    List<PortfolioHistoryModel>? history,
    bool? isLoading,
    String? error,
  }) {
    return PortfolioState(
      totalPortfolioValue: totalPortfolioValue ?? this.totalPortfolioValue,
      availableCash: availableCash ?? this.availableCash,
      investedAmount: investedAmount ?? this.investedAmount,
      oneDayReturn: oneDayReturn ?? this.oneDayReturn,
      oneDayReturnPercentage: oneDayReturnPercentage ?? this.oneDayReturnPercentage,
      totalReturn: totalReturn ?? this.totalReturn,
      totalReturnPercentage: totalReturnPercentage ?? this.totalReturnPercentage,
      holdings: holdings ?? this.holdings,
      transactions: transactions ?? this.transactions,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final Ref _ref;

  PortfolioNotifier(this._ref) : super(PortfolioState.initial());

  Future<void> fetchPortfolioData() async {
    state = state.copyWith(isLoading: true, error: null);
    final client = _ref.read(apiClientProvider);

    try {
      final summaryRes = await client.request('/api/portfolio/summary/', method: 'GET');
      final holdingsRes = await client.request('/api/portfolio/holdings/', method: 'GET');
      final txRes = await client.request('/api/portfolio/transactions/', method: 'GET');
      final historyRes = await client.request('/api/portfolio/history/', method: 'GET');

      if (summaryRes.statusCode == 200 &&
          holdingsRes.statusCode == 200 &&
          txRes.statusCode == 200 &&
          historyRes.statusCode == 200) {
        final summary = jsonDecode(summaryRes.body);
        final List<dynamic> holdingsJson = jsonDecode(holdingsRes.body);
        final List<dynamic> txJson = jsonDecode(txRes.body);
        final List<dynamic> historyJson = jsonDecode(historyRes.body);

        final holdings = holdingsJson.map((x) => HoldingModel.fromJson(x)).toList();
        final transactions = txJson.map((x) => TransactionModel.fromJson(x)).toList();
        final history = historyJson.map((x) => PortfolioHistoryModel.fromJson(x)).toList();

        state = PortfolioState(
          totalPortfolioValue: double.tryParse(summary['total_portfolio_value'].toString()) ?? 100000.0,
          availableCash: double.tryParse(summary['available_cash'].toString()) ?? 100000.0,
          investedAmount: double.tryParse(summary['invested_amount'].toString()) ?? 0.0,
          oneDayReturn: double.tryParse(summary['one_day_return'].toString()) ?? 0.0,
          oneDayReturnPercentage: double.tryParse(summary['one_day_return_percentage'].toString()) ?? 0.0,
          totalReturn: double.tryParse(summary['total_return'].toString()) ?? 0.0,
          totalReturnPercentage: double.tryParse(summary['total_return_percentage'].toString()) ?? 0.0,
          holdings: holdings,
          transactions: transactions,
          history: history,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to compile portfolio. API status error.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network connectivity issue compiled holdings metrics.',
      );
    }
  }

  Future<String?> buyStock(String symbol, int quantity, double price) async {
    final client = _ref.read(apiClientProvider);
    try {
      final response = await client.request(
        '/api/portfolio/buy/',
        method: 'POST',
        body: {
          'stock_symbol': symbol,
          'quantity': quantity,
          'price': price,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPortfolioData();
        return null; // Success
      } else {
        return data['error'] ?? data['detail'] ?? 'Failed to execute Buy transaction.';
      }
    } catch (e) {
      return 'Network connection failed during trade execution.';
    }
  }

  Future<String?> sellStock(String symbol, int quantity) async {
    final client = _ref.read(apiClientProvider);
    try {
      final response = await client.request(
        '/api/portfolio/sell/',
        method: 'POST',
        body: {
          'stock_symbol': symbol,
          'quantity': quantity,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPortfolioData();
        return null; // Success
      } else {
        return data['error'] ?? data['detail'] ?? 'Failed to execute Sell transaction.';
      }
    } catch (e) {
      return 'Network connection failed during trade execution.';
    }
  }

  Future<String?> depositCash(double amount, String bankName) async {
    final client = _ref.read(apiClientProvider);
    try {
      final response = await client.request(
        '/api/portfolio/deposit/',
        method: 'POST',
        body: {
          'amount': amount,
          'bank_name': bankName,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPortfolioData();
        return null; // Success
      } else {
        return data['error'] ?? data['detail'] ?? 'Failed to execute Deposit.';
      }
    } catch (e) {
      return 'Network connection failed during deposit execution.';
    }
  }

  Future<String?> withdrawCash(double amount, String bankName) async {
    final client = _ref.read(apiClientProvider);
    try {
      final response = await client.request(
        '/api/portfolio/withdraw/',
        method: 'POST',
        body: {
          'amount': amount,
          'bank_name': bankName,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPortfolioData();
        return null; // Success
      } else {
        return data['error'] ?? data['detail'] ?? 'Failed to execute Withdrawal.';
      }
    } catch (e) {
      return 'Network connection failed during withdrawal execution.';
    }
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  return PortfolioNotifier(ref);
});
