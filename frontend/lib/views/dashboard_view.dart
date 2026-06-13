import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import 'deposit_view.dart';
import 'withdrawal_view.dart';
import 'widgets/donut_chart_painter.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(marketProvider.notifier).fetchNifty50AndWatchlist();
      ref.read(portfolioProvider.notifier).fetchPortfolioData();
    });
  }

  String _formatCompact(double value) {
    final integerVal = value.toInt();
    final cents = ((value - integerVal) * 100).toInt().toString().padLeft(2, '0');
    
    final reversedChars = integerVal.toString().split('').reversed.toList();
    final List<String> formattedReversed = [];
    
    for (int i = 0; i < reversedChars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formattedReversed.add('.');
      }
      formattedReversed.add(reversedChars[i]);
    }
    
    final formattedInt = formattedReversed.reversed.join('');
    return "$formattedInt.$cents";
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM dd').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final market = ref.watch(marketProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == AppThemeMode.dark;

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    Widget mainContent = Column(
      children: [
        // Pinned Header
        _buildHeader(context, isDark),

        // White curved sheet
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            clipBehavior: Clip.antiAlias,
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await ref.read(marketProvider.notifier).fetchNifty50AndWatchlist();
                await ref.read(portfolioProvider.notifier).fetchPortfolioData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance & Dropdown Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Available Balance",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "\$${_formatCompact(portfolio.availableCash)}",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        // Dropdown "Month"
                        _buildDropdown(isDark),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Net Worth Line/Area Chart (Custom Painted)
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: PortfolioChartPainter(
                          history: portfolio.history,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dates Legend
                    _buildChartLegend(portfolio.history),
                    const SizedBox(height: 24),

                    // Spent and Earned row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpentEarnedCard(
                            isSpent: true,
                            amount: "\$0.00",
                            label: "Spent",
                            iconColor: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSpentEarnedCard(
                            isSpent: false,
                            amount: "\$${_formatCompact(portfolio.totalPortfolioValue - 100000.0 >= 0 ? portfolio.totalPortfolioValue - 100000.0 : 0.0)}",
                            label: "Profit / Return",
                            iconColor: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAllocationCard(portfolio, isDark),
                    const SizedBox(height: 28),

                    // Top Stock list section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Top Stock",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(activePageProvider.notifier).state = ActivePage.trade;
                          },
                          child: const Text(
                            "View All",
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Live Stock feeds
                    _buildTopStocksList(market, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F1E),
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 30),
            width: 390,
            height: 800,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF1E293B), width: 8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: mainContent,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: mainContent,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Portfolio",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Row(
            children: [
              // Theme Toggle Mode
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Withdraw Cash Button (Minus)
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WithdrawalView()),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.remove, color: Color(0xFFEF4444), size: 20),
                ),
              ),
              const SizedBox(width: 4),

              // Deposit Cash Button (Add)
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DepositView()),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFC5FF29), size: 20),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Month",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white : Colors.black, size: 14),
        ],
      ),
    );
  }

  Widget _buildChartLegend(List<PortfolioHistoryModel> history) {
    final List<String> dates = history.isNotEmpty
        ? history.map((e) => _formatDate(e.date)).toList()
        : ["Dec 22", "Dec 23", "Dec 24", "Dec 25", "Dec 26"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dates.map((date) {
        return Text(
          date,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpentEarnedCard({
    required bool isSpent,
    required String amount,
    required String label,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSpent ? Icons.arrow_outward : Icons.call_received,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopStocksList(MarketState market, bool isDark) {
    if (market.stocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black),
        ),
      );
    }

    final topStocks = market.stocks.take(3).toList();

    return Column(
      children: topStocks.map((stock) {
        final changePct = stock.changePercentage ?? 0.0;
        final isPositive = changePct >= 0;
        final currencyFormatInRupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isPositive ? const Color(0xFFE2FBE7) : const Color(0xFFFDE8E8),
                radius: 20,
                child: Text(
                  stock.symbol.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.name,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stock.currentPrice != null ? currencyFormatInRupee.format(stock.currentPrice) : '₹--',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${isPositive ? "+" : ""}${changePct.toStringAsFixed(2)}%",
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllocationCard(PortfolioState portfolio, bool isDark) {
    final Map<String, double> assetValues = {"CASH": portfolio.availableCash};
    for (var h in portfolio.holdings) {
      if (h.quantity > 0) {
        assetValues[h.stockSymbol] = h.quantity * h.currentPrice;
      }
    }

    final double totalVal = assetValues.values.fold(0.0, (s, v) => s + v);

    final colors = [
      const Color(0xFF14B8A6), // CASH: Teal
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEF4444), // Crimson
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
    ];

    final List<Widget> legendRows = [];
    int colorIdx = 0;
    assetValues.forEach((key, val) {
      if (val > 0) {
        final weight = totalVal > 0 ? (val / totalVal * 100) : 0.0;
        final color = colors[colorIdx % colors.length];
        legendRows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  "${weight.toStringAsFixed(1)}%",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
        colorIdx++;
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Asset Allocation",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    assetValues: assetValues,
                    colors: colors,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: legendRows.isNotEmpty
                      ? legendRows
                      : [
                          Text(
                            "No assets allocated yet.",
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          )
                        ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PortfolioChartPainter extends CustomPainter {
  final List<PortfolioHistoryModel> history;
  final bool isDark;

  PortfolioChartPainter({required this.history, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final chartWidth = width - 50;

    final Paint linePaint = Paint()
      ..color = isDark ? const Color(0xFF374151).withOpacity(0.4) : Colors.grey.shade200
      ..strokeWidth = 1.0;

    final double step = height / 4;
    for (int i = 0; i <= 4; i++) {
      final y = step * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), linePaint);
    }

    if (history.isEmpty) {
      return;
    }

    double minVal = history.map((e) => e.netWorth).reduce(math.min);
    double maxVal = history.map((e) => e.netWorth).reduce(math.max);

    if (maxVal == minVal) {
      maxVal += 100.0;
      minVal -= 100.0;
    }

    final double padding = (maxVal - minVal) * 0.15;
    maxVal += padding;
    minVal -= padding;

    final double range = maxVal - minVal;

    const TextStyle labelStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final values = [
      maxVal,
      maxVal - range * 0.25,
      maxVal - range * 0.5,
      maxVal - range * 0.75,
      minVal
    ];

    for (int i = 0; i < values.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: _formatValue(values[i]), style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      canvas.drawLine(
        Offset(chartWidth, step * i),
        Offset(chartWidth + 5, step * i),
        linePaint,
      );
      textPainter.paint(
        canvas,
        Offset(chartWidth + 8, (step * i) - (textPainter.height / 2)),
      );
    }

    final points = <Offset>[];
    final double xStep = chartWidth / (history.length - 1);

    for (int i = 0; i < history.length; i++) {
      final x = i * xStep;
      final y = height - ((history[i].netWorth - minVal) / range * height);
      points.add(Offset(x, y));
    }

    final Path areaPath = Path();
    areaPath.moveTo(points.first.dx, height);
    areaPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      areaPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }
    areaPath.lineTo(points.last.dx, height);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFC5FF29).withOpacity(0.35),
          const Color(0xFFC5FF29).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, chartWidth, height));

    canvas.drawPath(areaPath, areaPaint);

    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    final Paint lineStrokePaint = Paint()
      ..color = const Color(0xFFC5FF29)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, lineStrokePaint);

    final lastPoint = points.last;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFC5FF29)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(lastPoint, 6, dotPaint);
    canvas.drawCircle(lastPoint, 6, borderPaint);
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return "\$${(value / 1000).toStringAsFixed(1)}k";
    }
    return "\$${value.toStringAsFixed(0)}";
  }

  @override
  bool shouldRepaint(covariant PortfolioChartPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.isDark != isDark;
  }
}
