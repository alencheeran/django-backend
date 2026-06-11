import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';
import '../providers/navigation_provider.dart';
import 'dashboard_view.dart';

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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Stocks you are actively monitoring',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: watchedStocks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_outline, color: Color(0xFF64748B), size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Your watchlist is empty.',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add symbols to your watchlist from the Dashboard.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: watchedStocks.length,
                      separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
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
