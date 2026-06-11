import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/portfolio_provider.dart';
import '../providers/navigation_provider.dart';

class HoldingsView extends ConsumerStatefulWidget {
  const HoldingsView({super.key});

  @override
  ConsumerState<HoldingsView> createState() => _HoldingsViewState();
}

class _HoldingsViewState extends ConsumerState<HoldingsView> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(portfolioProvider.notifier).fetchPortfolioData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final holdings = portfolio.holdings;

    final profitColor = portfolio.totalReturn >= 0.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Text(
            'Equity Holdings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your active equity portfolios and open market positions',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),

          // Holdings Metrics
          Row(
            children: [
              Expanded(
                child: _buildHoldingMetricCard(
                  'Portfolio Current Value',
                  currencyFormat.format(portfolio.totalPortfolioValue - portfolio.availableCash),
                  Icons.trending_up,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHoldingMetricCard(
                  'Net Cost Invested',
                  currencyFormat.format(portfolio.investedAmount),
                  Icons.monetization_on_outlined,
                  const Color(0xFF818CF8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHoldingMetricCard(
                  'Total Unrealized P&L',
                  currencyFormat.format(portfolio.totalReturn),
                  Icons.percent,
                  profitColor,
                  suffix: '${portfolio.totalReturnPercentage.toStringAsFixed(2)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Holdings list table
          Container(
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
                    'Active Equities Position Ledger',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(color: Color(0xFF334155), height: 1),
                if (holdings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_outline, color: Color(0xFF64748B), size: 48),
                          SizedBox(height: 16),
                          Text(
                            'No active positions owned.',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Visit the Trade Room to buy Nifty 50 shares.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: holdings.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
                    itemBuilder: (context, index) {
                      final pos = holdings[index];
                      final isPositive = pos.profitLoss >= 0.0;
                      final pnlColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                      return ListTile(
                        onTap: () {
                          ref.read(activeStockSymbolProvider.notifier).state = pos.stockSymbol;
                          ref.read(activePageProvider.notifier).state = ActivePage.trade;
                        },
                        title: Row(
                          children: [
                            Text(pos.stockSymbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${pos.quantity} Shares',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Text('Avg: ${currencyFormat.format(pos.averageBuyPrice)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Color(0xFF64748B))),
                            const SizedBox(width: 8),
                            Text('LTP: ${currencyFormat.format(pos.currentPrice)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(pos.currentValue),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${isPositive ? "+" : ""}${currencyFormat.format(pos.profitLoss)} (${pos.profitLossPercentage.toStringAsFixed(2)}%)',
                                  style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHoldingMetricCard(String title, String value, IconData icon, Color color, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 8),
                Text(
                  suffix,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
