import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/navigation_provider.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    // Fetch data on init
    Future.microtask(() {
      ref.read(marketProvider.notifier).fetchNifty50AndWatchlist();
      ref.read(portfolioProvider.notifier).fetchPortfolioData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final market = ref.watch(marketProvider);

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(marketProvider.notifier).fetchNifty50AndWatchlist();
        await ref.read(portfolioProvider.notifier).fetchPortfolioData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Live equity price feeds and portfolio summary metrics',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(marketProvider.notifier).fetchNifty50AndWatchlist();
                    ref.read(portfolioProvider.notifier).fetchPortfolioData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Grid
            _buildMetricsGrid(portfolio),
            const SizedBox(height: 32),

            // Live Stocks & Watchlist Preview
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildStockTable(market),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildWatchlistPreview(market),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildStockTable(market),
                  const SizedBox(height: 24),
                  _buildWatchlistPreview(market),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(PortfolioState portfolio) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: [
            _buildMetricCard(
              title: 'Portfolio Net Worth',
              value: currencyFormat.format(portfolio.totalPortfolioValue),
              subtitle: 'Investments + Balance',
              icon: Icons.pie_chart,
              iconColor: const Color(0xFF6366F1),
              trendValue: portfolio.totalReturn,
              trendPct: portfolio.totalReturnPercentage,
              trendLabel: 'All-time return',
            ),
            _buildMetricCard(
              title: 'Available Capital',
              value: currencyFormat.format(portfolio.availableCash),
              subtitle: 'Cash ready to deploy',
              icon: Icons.wallet,
              iconColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Invested Capital',
              value: currencyFormat.format(portfolio.investedAmount),
              subtitle: 'Value at cost basis',
              icon: Icons.credit_card,
              iconColor: const Color(0xFF818CF8),
            ),
            _buildMetricCard(
              title: 'Daily Performance',
              value: currencyFormat.format(portfolio.oneDayReturn.abs()),
              subtitle: 'Today\'s valuation change',
              icon: Icons.show_chart,
              iconColor: const Color(0xFFF59E0B),
              trendValue: portfolio.oneDayReturn,
              trendPct: portfolio.oneDayReturnPercentage,
              trendLabel: 'Daily change',
              useAbsoluteVal: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    double? trendValue,
    double? trendPct,
    String? trendLabel,
    bool useAbsoluteVal = true,
  }) {
    final isPositive = (trendValue ?? 0.0) >= 0.0;
    final trendColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          if (trendValue != null && trendPct != null)
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trendColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trendPct.toStringAsFixed(2)}%',
                  style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trendLabel ?? '',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildStockTable(MarketState market) {
    if (market.isLoading && market.stocks.isEmpty) {
      return const Card(
        color: Color(0xFF1E293B),
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        ),
      );
    }

    if (market.error != null && market.stocks.isEmpty) {
      return Card(
        color: const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text(market.error!, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Nifty 50 Equities List',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: market.stocks.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
            itemBuilder: (context, index) {
              final stock = market.stocks[index];
              final isWatching = market.watchlistSymbols.contains(stock.symbol);
              return StockListRow(
                stock: stock,
                isWatching: isWatching,
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
        ],
      ),
    );
  }

  Widget _buildWatchlistPreview(MarketState market) {
    final watchedStocks = market.stocks.where((s) => market.watchlistSymbols.contains(s.symbol)).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Watchlist',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => ref.read(activePageProvider.notifier).state = ActivePage.watchlist,
                child: const Text('View All', style: TextStyle(color: Color(0xFF6366F1))),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          if (watchedStocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Icon(Icons.star_outline, color: Color(0xFF64748B), size: 36),
                  SizedBox(height: 8),
                  Text(
                    'No items watched yet.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: watchedStocks.length,
              itemBuilder: (context, index) {
                final stock = watchedStocks[index];
                final changePct = stock.changePercentage ?? 0.0;
                final isPositive = changePct >= 0;
                final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(stock.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(stock.name, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11), overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stock.currentPrice != null ? currencyFormat.format(stock.currentPrice) : '₹--',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${isPositive ? "+" : ""}${changePct.toStringAsFixed(2)}%',
                        style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(activeStockSymbolProvider.notifier).state = stock.symbol;
                    ref.read(activePageProvider.notifier).state = ActivePage.trade;
                  },
                );
              },
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          widget.stock.name,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
