import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../providers/market_provider.dart';
import '../providers/navigation_provider.dart';

class WatchlistView extends ConsumerWidget {
  const WatchlistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final watchedStocks = market.stocks.where((s) => market.watchlistSymbols.contains(s.symbol)).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Watchlist',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Stocks you are actively monitoring',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: watchedStocks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_outline, color: Color(0xFF64748B), size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Your watchlist is empty.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add symbols to your watchlist from the Dashboard.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 100.0),
                      itemCount: watchedStocks.length,
                      separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor, height: 1),
                      itemBuilder: (context, index) {
                        final stock = watchedStocks[index];
                        return StockListRow(
                          stock: stock,
                          isWatching: true,
                          onWatchlistToggle: () {
                            ref.read(marketProvider.notifier).toggleWatchlist(stock.symbol);
                          },
                          onTap: () {
                            ref.read(activeStockSymbolProvider.notifier).state = stock.symbol;
                            ref.read(activePageProvider.notifier).state = ActivePage.trade;
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class StockListRow extends StatefulWidget {
  final StockModel stock;
  final bool isWatching;
  final VoidCallback onWatchlistToggle;
  final VoidCallback onTap;

  const StockListRow({
    super.key,
    required this.stock,
    required this.isWatching,
    required this.onWatchlistToggle,
    required this.onTap,
  });

  @override
  State<StockListRow> createState() => _StockListRowState();
}

class _StockListRowState extends State<StockListRow> {
  Color _rowColor = Colors.transparent;
  double? _prevPrice;

  @override
  void didUpdateWidget(covariant StockListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stock.currentPrice != null && _prevPrice != null && widget.stock.currentPrice != _prevPrice) {
      final isUp = widget.stock.currentPrice! > _prevPrice!;
      setState(() {
        _rowColor = isUp ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _rowColor = Colors.transparent;
          });
        }
      });
    }
    _prevPrice = widget.stock.currentPrice;
  }

  @override
  void initState() {
    super.initState();
    _prevPrice = widget.stock.currentPrice;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final changePct = widget.stock.changePercentage ?? 0.0;
    final changeVal = widget.stock.change ?? 0.0;
    final isPositive = changePct >= 0.0;
    final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: _rowColor,
      child: ListTile(
        onTap: widget.onTap,
        leading: IconButton(
          icon: Icon(
            widget.isWatching ? Icons.star : Icons.star_border,
            color: widget.isWatching ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
          ),
          onPressed: widget.onWatchlistToggle,
        ),
        title: Text(
          widget.stock.symbol,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          widget.stock.name,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.stock.currentPrice != null ? currencyFormat.format(widget.stock.currentPrice) : '₹--',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${isPositive ? "+" : ""}${changeVal.toStringAsFixed(2)} (${isPositive ? "+" : ""}${changePct.toStringAsFixed(2)}%)',
                  style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}
