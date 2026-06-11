import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/stock.dart';
import 'api_client.dart';
import 'settings_provider.dart';

class MarketState {
  final List<StockModel> stocks;
  final List<String> watchlistSymbols;
  final bool isLoading;
  final String? error;

  MarketState({
    required this.stocks,
    required this.watchlistSymbols,
    required this.isLoading,
    this.error,
  });

  MarketState copyWith({
    List<StockModel>? stocks,
    List<String>? watchlistSymbols,
    bool? isLoading,
    String? error,
  }) {
    return MarketState(
      stocks: stocks ?? this.stocks,
      watchlistSymbols: watchlistSymbols ?? this.watchlistSymbols,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MarketNotifier extends StateNotifier<MarketState> {
  final Ref _ref;
  WebSocketChannel? _channel;
  bool _disposed = false;

  MarketNotifier(this._ref)
      : super(MarketState(
          stocks: [],
          watchlistSymbols: [],
          isLoading: false,
        ));

  @override
  void dispose() {
    _disposed = true;
    disconnectWebSocket();
    super.dispose();
  }

  Future<void> fetchNifty50AndWatchlist() async {
    state = state.copyWith(isLoading: true, error: null);
    final client = _ref.read(apiClientProvider);

    try {
      // Fetch Nifty50 Stocks
      final stockRes = await client.request('/api/stocks/nifty50/', method: 'GET');
      // Fetch Watchlist
      final watchRes = await client.request('/api/portfolio/watchlist/', method: 'GET');

      if (stockRes.statusCode == 200 && watchRes.statusCode == 200) {
        final List<dynamic> stockJson = jsonDecode(stockRes.body);
        final List<dynamic> watchJson = jsonDecode(watchRes.body);

        final stocks = stockJson.map((x) => StockModel.fromJson(x)).toList();
        final watchlistSymbols = watchJson.map((x) => x['stock_symbol'] as String).toList();

        state = MarketState(
          stocks: stocks,
          watchlistSymbols: watchlistSymbols,
          isLoading: false,
        );

        // Connect WebSocket stream
        connectWebSocket();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch market data. Status: ${stockRes.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network connection error fetching market indices.',
      );
    }
  }

  void connectWebSocket() {
    if (_disposed || _channel != null) return;
    final settings = _ref.read(settingsProvider);
    final wsUri = Uri.parse('${settings.wsUrl}/ws/stocks/');

    try {
      _channel = WebSocketChannel.connect(wsUri);

      // Subscribe to all Nifty 50 stocks
      final symbols = state.stocks.map((s) => s.symbol).toList();
      if (symbols.isNotEmpty) {
        _channel!.sink.add(jsonEncode({
          'action': 'subscribe',
          'symbols': symbols,
        }));
      }

      _channel!.stream.listen((message) {
        if (_disposed) return;
        final data = jsonDecode(message);
        if (data['type'] == 'stock_update') {
          final List<dynamic> stockUpdates = data['stocks'];
          _updateStockPrices(stockUpdates);
        }
      }, onError: (err) {
        disconnectWebSocket();
        if (!_disposed) {
          Future.delayed(const Duration(seconds: 5), () => connectWebSocket());
        }
      }, onDone: () {
        disconnectWebSocket();
        if (!_disposed) {
          Future.delayed(const Duration(seconds: 5), () => connectWebSocket());
        }
      });
    } catch (e) {
      if (!_disposed) {
        Future.delayed(const Duration(seconds: 5), () => connectWebSocket());
      }
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  void _updateStockPrices(List<dynamic> updates) {
    final updatedStocks = state.stocks.map((stock) {
      final update = updates.firstWhere(
        (u) => u['symbol'] == stock.symbol,
        orElse: () => null,
      );
      if (update != null) {
        return stock.copyWith(
          currentPrice: double.tryParse(update['price'].toString()),
          change: double.tryParse(update['change'].toString()),
          changePercentage: double.tryParse(update['change_percentage'].toString()),
        );
      }
      return stock;
    }).toList();

    state = state.copyWith(stocks: updatedStocks);
  }

  Future<void> toggleWatchlist(String symbol) async {
    final apiClient = _ref.read(apiClientProvider);

    final isWatching = state.watchlistSymbols.contains(symbol);
    final updatedWatchlist = List<String>.from(state.watchlistSymbols);
    
    if (isWatching) {
      updatedWatchlist.remove(symbol);
    } else {
      updatedWatchlist.add(symbol);
    }
    
    state = state.copyWith(watchlistSymbols: updatedWatchlist);

    try {
      final response = await apiClient.request(
        '/api/portfolio/watchlist/toggle/',
        method: 'POST',
        body: {'stock_symbol': symbol},
      );

      if (response.statusCode != 200) {
        // Revert
        fetchNifty50AndWatchlist();
      }
    } catch (e) {
      // Revert
      fetchNifty50AndWatchlist();
    }
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier(ref);
});
