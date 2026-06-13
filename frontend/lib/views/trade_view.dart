import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../providers/alert_provider.dart';

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
            backgroundColor: Theme.of(context).colorScheme.secondary,
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
    final changeColor = isUp ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error;

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Stock Overview Details
          size.width < 600
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stock.symbol,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
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
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            color: Color(0xFFC5FF29),
                          ),
                          onPressed: () => _showAddAlertSheet(context, stock.symbol),
                        ),
                      ],
                    ),
                    Text(stock.name, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          stock.currentPrice != null ? currencyFormat.format(stock.currentPrice) : '₹--',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${isUp ? "+" : ""}${(stock.change ?? 0.0).toStringAsFixed(2)} (${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%)',
                          style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _buildPeriodGroup(period),
                      ),
                    ),
                  ],
                )
              : Row(
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
                                      color: Theme.of(context).colorScheme.onSurface,
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
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFFC5FF29),
                                ),
                                onPressed: () => _showAddAlertSheet(context, stock.symbol),
                              ),
                            ],
                          ),
                          Text(stock.name, style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                stock.currentPrice != null ? currencyFormat.format(stock.currentPrice) : '₹--',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
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
                      _buildChartCard(symbol, stock),
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
                _buildChartCard(symbol, stock),
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
      color: const Color(0xFF64748B),
      selectedColor: Colors.white,
      fillColor: Theme.of(context).colorScheme.primary,
      borderColor: Theme.of(context).dividerColor,
      selectedBorderColor: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      children: periods.map((p) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(p.toUpperCase()),
      )).toList(),
    );
  }

  Widget _buildChartCard(String symbol, StockModel stock) {
    final chartFuture = ref.watch(chartCandlesProvider(symbol));

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: chartFuture.when(
        data: (candles) {
          if (candles.isEmpty) {
            return Center(child: Text('No candle history available.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))));
          }

          List<Candle> chartCandles = candles;
          if (candles.isNotEmpty && stock.currentPrice != null) {
            final newest = candles.first;
            final livePrice = stock.currentPrice!;
            chartCandles = List<Candle>.from(candles);
            chartCandles[0] = Candle(
              date: newest.date,
              open: newest.open,
              close: livePrice,
              high: math.max(newest.high, livePrice),
              low: math.min(newest.low, livePrice),
              volume: newest.volume,
            );
          }

          return Candlesticks(
            candles: chartCandles,
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(
                err.toString().replaceAll('Exception:', ''),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                      color: _activeOrderTab == 0 ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        bottom: BorderSide(
                          color: _activeOrderTab == 0 ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'BUY ORDER',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
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
                      color: _activeOrderTab == 1 ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        bottom: BorderSide(
                          color: _activeOrderTab == 1 ? Theme.of(context).colorScheme.error : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'SELL ORDER',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
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
                    const Text('Product Class', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    Text(
                      _activeOrderTab == 0 ? 'EQUITY DELIVERY BUY' : 'EQUITY DELIVERY SELL',
                      style: TextStyle(color: _activeOrderTab == 0 ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quantity Input
                TextFormField(
                  controller: _quantityController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Shares Quantity',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
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
                    const Text('Execution Rate', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    Text(
                      price > 0 ? currencyFormat.format(price) : '₹--',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Total calculations
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_activeOrderTab == 0 ? 'Required Capital' : 'Total Est. Proceeds', style: const TextStyle(color: Color(0xFF64748B))),
                    Text(
                      currencyFormat.format(totalCost),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
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
                    backgroundColor: _activeOrderTab == 0 ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                    disabledBackgroundColor: Theme.of(context).dividerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
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

  void _showAddAlertSheet(BuildContext context, String symbol) {
    HapticFeedback.lightImpact();
    final stock = ref.read(marketProvider).stocks.firstWhere((s) => s.symbol == symbol);
    final currentPrice = stock.currentPrice ?? 0.0;
    
    final _alertPriceController = TextEditingController(text: currentPrice.toStringAsFixed(2));
    bool _isAbove = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final alerts = ref.watch(alertProvider).where((a) => a.symbol == symbol).toList();
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Set Price Alert for $symbol",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Current Live Price: ₹${currentPrice.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _alertPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Target Price (₹)",
                      labelStyle: TextStyle(color: Color(0xFF64748B)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC5FF29))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Trigger when price goes:",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Above"),
                            selected: _isAbove,
                            selectedColor: const Color(0xFFC5FF29),
                            onSelected: (selected) {
                              if (selected) {
                                HapticFeedback.lightImpact();
                                setSheetState(() => _isAbove = true);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text("Below"),
                            selected: !_isAbove,
                            selectedColor: const Color(0xFFC5FF29),
                            onSelected: (selected) {
                              if (selected) {
                                HapticFeedback.lightImpact();
                                setSheetState(() => _isAbove = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5FF29),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final val = double.tryParse(_alertPriceController.text);
                      if (val == null || val <= 0) {
                        HapticFeedback.vibrate();
                        return;
                      }
                      HapticFeedback.heavyImpact();
                      ref.read(alertProvider.notifier).addAlert(symbol, val, _isAbove);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Price Alert set for $symbol at ₹${val.toStringAsFixed(2)}!"),
                          backgroundColor: const Color(0xFFC5FF29),
                        ),
                      );
                    },
                    child: const Text("Create Alert", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF334155)),
                    const SizedBox(height: 12),
                    const Text(
                      "Active Alerts for this Stock",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.asMap().entries.map((entry) {
                      final alert = entry.value;
                      final actualIndex = ref.read(alertProvider).indexOf(alert);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Trigger when price is ${alert.isAbove ? '≥' : '≤'} ₹${alert.targetPrice.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(alertProvider.notifier).removeAlert(actualIndex);
                            setSheetState(() {});
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
