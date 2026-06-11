import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:candlesticks/candlesticks.dart';
import '../models/stock.dart';
import '../models/candle.dart';
import '../models/holding.dart';
import '../providers/api_client.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/navigation_provider.dart';

final activePeriodProvider = StateProvider<String>((ref) => '1mo');

final chartCandlesProvider = FutureProvider.family<List<Candle>, String>((ref, symbol) async {
  final apiClient = ref.read(apiClientProvider);
  final period = ref.watch(activePeriodProvider);

  // Normalize NSE symbol extensions
  final ticker = symbol.endsWith('.NS') ? symbol : '$symbol.NS';

  final res = await apiClient.request(
    '/api/stocks/$ticker/chart/?period=$period&interval=1d',
    method: 'GET',
  );

  if (res.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List<dynamic> candlesJson = data['candles'];
    // candlesticks package requires newest candles first (descending chronological order)
    final candles = candlesJson.map((x) => CandleMapper.fromJson(x)).toList();
    return candles.reversed.toList();
  } else {
    throw Exception('No historical chart data returned by yfinance API.');
  }
});

class TradeView extends ConsumerStatefulWidget {
  const TradeView({super.key});

  @override
  ConsumerState<TradeView> createState() => _TradeViewState();
}

class _TradeViewState extends ConsumerState<TradeView> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _quantityController = TextEditingController(text: '5');
  int _activeOrderTab = 0; // 0 = Buy, 1 = Sell
  bool _isExecuting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _executeOrder(StockModel stock, int ownedShares) async {
    final qtyText = _quantityController.text.trim();
    final qty = int.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid shares quantity.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_activeOrderTab == 1 && qty > ownedShares) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient shares owned to execute sell.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isExecuting = true);

    String? error;
    if (_activeOrderTab == 0) {
      error = await ref.read(portfolioProvider.notifier).buyStock(
            stock.symbol,
            qty,
            stock.currentPrice ?? 0.0,
          );
    } else {
      error = await ref.read(portfolioProvider.notifier).sellStock(stock.symbol, qty);
    }

    if (mounted) {
      setState(() => _isExecuting = false);
      if (error != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order Rejected', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            content: Text(error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully executed ${_activeOrderTab == 0 ? 'Buy' : 'Sell'} order for $qty shares of ${stock.symbol}!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _quantityController.text = '5';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(activeStockSymbolProvider);
    final market = ref.watch(marketProvider);
    final portfolio = ref.watch(portfolioProvider);
    final period = ref.watch(activePeriodProvider);

    // Find active stock metadata from list
    final stock = market.stocks.firstWhere(
      (s) => s.symbol == symbol,
      orElse: () => StockModel(symbol: symbol, name: symbol.replaceAll('.NS', '')),
    );

    // Find owned shares for this ticker
    final holding = portfolio.holdings.firstWhere(
      (h) => h.stockSymbol == symbol,
      orElse: () => HoldingModel(
        stockSymbol: symbol,
        quantity: 0,
        averageBuyPrice: 0.0,
        currentPrice: 0.0,
        currentValue: 0.0,
        profitLoss: 0.0,
        profitLossPercentage: 0.0,
      ),
    );

    final isWatching = market.watchlistSymbols.contains(symbol);
    final changePct = stock.changePercentage ?? 0.0;
    final isUp = changePct >= 0.0;
    final changeColor = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Stock Overview Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stock.symbol,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            isWatching ? Icons.star : Icons.star_border,
                            color: isWatching ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                          ),
                          onPressed: () => ref.read(marketProvider.notifier).toggleWatchlist(stock.symbol),
                        ),
                      ],
                    ),
                    Text(stock.name, style: const TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          stock.currentPrice != null ? currencyFormat.format(stock.currentPrice) : '₹--',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${isUp ? "+" : ""}${(stock.change ?? 0.0).toStringAsFixed(2)} (${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%)',
                          style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Period filters selector
              _buildPeriodGroup(period),
            ],
          ),
          const SizedBox(height: 24),

          // Platform layout split
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildChartCard(symbol),
                      const SizedBox(height: 16),
                      _buildStatsRow(stock),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildOrderCard(stock, holding, portfolio.availableCash),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildChartCard(symbol),
                const SizedBox(height: 16),
                _buildStatsRow(stock),
                const SizedBox(height: 24),
                _buildOrderCard(stock, holding, portfolio.availableCash),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodGroup(String currentPeriod) {
    const periods = ['1mo', '3mo', '6mo', '1y', '5y'];
    return ToggleButtons(
      isSelected: periods.map((p) => p == currentPeriod).toList(),
      onPressed: (index) {
        ref.read(activePeriodProvider.notifier).state = periods[index];
      },
      color: const Color(0xFF94A3B8),
      selectedColor: Colors.white,
      fillColor: const Color(0xFF6366F1),
      borderColor: const Color(0xFF334155),
      selectedBorderColor: const Color(0xFF6366F1),
      borderRadius: BorderRadius.circular(8),
      children: periods.map((p) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(p.toUpperCase()),
      )).toList(),
    );
  }

  Widget _buildChartCard(String symbol) {
    final chartFuture = ref.watch(chartCandlesProvider(symbol));

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: chartFuture.when(
        data: (candles) {
          if (candles.isEmpty) {
            return const Center(child: Text('No candle history available.', style: TextStyle(color: Colors.white70)));
          }
          return Candlesticks(
            candles: candles,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(
                err.toString().replaceAll('Exception:', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(StockModel stock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Today High', stock.high != null ? currencyFormat.format(stock.high) : '₹--'),
          _buildStatItem('Today Low', stock.low != null ? currencyFormat.format(stock.low) : '₹--'),
          _buildStatItem('Volume', stock.volume != null ? NumberFormat.compact().format(stock.volume) : '--'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOrderCard(StockModel stock, HoldingModel holding, double cash) {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = stock.currentPrice ?? 0.0;
    final totalCost = qty * price;

    final hasBalance = cash >= totalCost;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Buy / Sell Tab Switches
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeOrderTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _activeOrderTab == 0 ? Colors.transparent : const Color(0xFF0F172A).withOpacity(0.4),
                      border: Border(
                        bottom: BorderSide(
                          color: _activeOrderTab == 0 ? const Color(0xFF6366F1) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: const Text(
                      'BUY ORDER',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeOrderTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _activeOrderTab == 1 ? Colors.transparent : const Color(0xFF0F172A).withOpacity(0.4),
                      border: Border(
                        bottom: BorderSide(
                          color: _activeOrderTab == 1 ? const Color(0xFFEF4444) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: const Text(
                      'SELL ORDER',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Product Class', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text(
                      _activeOrderTab == 0 ? 'EQUITY DELIVERY BUY' : 'EQUITY DELIVERY SELL',
                      style: TextStyle(color: _activeOrderTab == 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quantity Input
                TextFormField(
                  controller: _quantityController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Shares Quantity',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  _activeOrderTab == 0 
                      ? 'You currently hold: ${holding.quantity} shares'
                      : 'Maximum available to sell: ${holding.quantity} shares',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 24),

                // Read-only rate display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Execution Rate', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    Text(
                      price > 0 ? currencyFormat.format(price) : '₹--',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Total calculations
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_activeOrderTab == 0 ? 'Required Capital' : 'Total Est. Proceeds', style: const TextStyle(color: Color(0xFF94A3B8))),
                    Text(
                      currencyFormat.format(totalCost),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Capital', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    Text(
                      currencyFormat.format(cash),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Order Action Button
                ElevatedButton(
                  onPressed: _isExecuting || (_activeOrderTab == 0 && !hasBalance) ? null : () => _executeOrder(stock, holding.quantity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeOrderTab == 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    disabledBackgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isExecuting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _activeOrderTab == 0 
                              ? (hasBalance ? 'BUY STOCK' : 'INSUFFICIENT CAPITAL')
                              : 'SELL STOCK',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
