import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/portfolio_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';

class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key});

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final dateFormat = DateFormat('MMMM dd, yyyy');
  final tradeDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  
  bool _showActivities = true; // True = Activities, False = Transactions

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
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
    if (value > 0 && value < 1) {
      return value.toStringAsFixed(5);
    }
    return "$formattedInt.$cents";
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final transactions = portfolio.transactions;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == AppThemeMode.dark;

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    final activities = transactions.where((tx) => tx.transactionType == 'DEP' || tx.transactionType == 'WIT').toList();
    final stockTrades = transactions.where((tx) => tx.transactionType == 'BUY' || tx.transactionType == 'SELL').toList();

    double totalDeposit = activities
        .where((tx) => tx.transactionType == 'DEP')
        .fold(0.0, (sum, tx) => sum + tx.totalValue);
    double totalWithdrawal = activities
        .where((tx) => tx.transactionType == 'WIT')
        .fold(0.0, (sum, tx) => sum + tx.totalValue);
    double netDeposits = totalDeposit - totalWithdrawal;
    double netWithdrawals = totalWithdrawal;

    Widget mainContent = Column(
      children: [
        // Pinned Header matching History
        _buildHeader(),

        // Curved Sheet Content
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Activities vs Transactions Sliding Selector
                _buildSegmentedTab(isDark),

                const SizedBox(height: 20),

                // Conditional view body
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      await ref.read(portfolioProvider.notifier).fetchPortfolioData();
                    },
                    child: _showActivities
                        ? _buildActivitiesBody(
                            activities,
                            totalDeposit,
                            totalWithdrawal,
                            netDeposits,
                            netWithdrawals,
                            isDark,
                          )
                        : _buildTransactionsBody(stockTrades, isDark),
                  ),
                ),
              ],
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

  Widget _buildHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "History",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showActivities = true;
                  });
                },
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _showActivities ? const Color(0xFFC5FF29) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Activities",
                    style: TextStyle(
                      color: _showActivities ? Colors.black : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showActivities = false;
                  });
                },
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: !_showActivities ? const Color(0xFFC5FF29) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Transactions",
                    style: TextStyle(
                      color: !_showActivities ? Colors.black : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesBody(
    List<TransactionModel> activities,
    double totalDeposit,
    double totalWithdrawal,
    double netDeposits,
    double netWithdrawals,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  label: "Total Deposit",
                  value: _formatCompact(totalDeposit == 0 ? 0.18732 : totalDeposit),
                  bgColor: isDark ? const Color(0xFF2E1A47) : const Color(0xFFF6E8FF),
                  textColor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryBox(
                  label: "Total withdrawal",
                  value: _formatCompact(totalWithdrawal == 0 ? 0.18732 : totalWithdrawal),
                  bgColor: isDark ? const Color(0xFF1A2E47) : const Color(0xFFE3F5FF),
                  textColor: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  label: "Net Deposits",
                  value: _formatCompact(netDeposits == 0 ? 0.18732 : netDeposits),
                  bgColor: isDark ? const Color(0xFF1A3D24) : const Color(0xFFE2FBE7),
                  textColor: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryBox(
                  label: "Net Withdrawals",
                  value: _formatCompact(netWithdrawals == 0 ? 0.18732 : netWithdrawals),
                  bgColor: isDark ? const Color(0xFF3D2E1A) : const Color(0xFFFFFBE3),
                  textColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          activities.isEmpty
              ? _buildEmptyState("No banking activities logged yet.", isDark)
              : _buildActivitiesList(activities, isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? textColor.withOpacity(0.8) : textColor.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(List<TransactionModel> activities, bool isDark) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (var tx in activities) {
      final key = dateFormat.format(tx.createdAt.toLocal());
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final dateKeys = grouped.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dateKeys.map((dateStr) {
        final dayTxList = grouped[dateStr]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                dateStr,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...dayTxList.map((tx) {
              final isDep = tx.transactionType == 'DEP';
              final label = isDep ? "Deposit via Bank BCA" : "Withdrawal to Bank BCA";
              final valueStr = "${isDep ? "+" : "-"}\$${_formatCompact(tx.totalValue)}";
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4C81),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "▲ BCA",
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valueStr,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF065F46) : const Color(0xFFE2FBE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Successful",
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsBody(List<TransactionModel> stockTrades, bool isDark) {
    if (stockTrades.isEmpty) {
      return _buildEmptyState("Execute a trade order in the Trade Room to generate transaction logs.", isDark);
    }

    final currencyFormatInRupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
      itemCount: stockTrades.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final tx = stockTrades[index];
        final isBuy = tx.transactionType == 'BUY';
        final typeColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.transactionType.toUpperCase(),
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tx.stockSymbol,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${tx.quantity} Shares',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tradeDateFormat.format(tx.createdAt.toLocal()),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatInRupee.format(tx.totalValue),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rate: ${currencyFormatInRupee.format(tx.price)}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String sub, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, color: Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 16),
            Text(
              "No logs found",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
