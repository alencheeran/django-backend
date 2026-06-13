import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/theme_provider.dart';
import 'widgets/share_card_modal.dart';

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(leaderboardProvider.notifier).fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final entries = state.entries;
    final auth = ref.watch(authProvider);
    final portfolio = ref.watch(portfolioProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == AppThemeMode.dark;

    // Settle user details
    final myEntryIndex = entries.indexWhere((e) => e.username == auth.username);
    final myEntry = myEntryIndex != -1 ? entries[myEntryIndex] : null;

    final myReturnPct = myEntry != null ? myEntry.totalReturnPercentage : portfolio.totalReturnPercentage;
    final myNetWorth = myEntry != null ? myEntry.totalPortfolioValue : portfolio.totalPortfolioValue;
    final myRank = myEntryIndex != -1 ? "${myEntryIndex + 1}" : "N/A";

    String myBadge = "Getting Started 🥚";
    if (myReturnPct > 0 && myReturnPct < 5) {
      myBadge = "Novice Trader 🌱";
    } else if (myReturnPct >= 5 && myReturnPct < 20) {
      myBadge = "Profit Maker ⚡";
    } else if (myReturnPct >= 20) {
      myBadge = "Paper Trade Guru 🏆";
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await ref.read(leaderboardProvider.notifier).fetchLeaderboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaderboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rankings sorted by net virtual portfolio value',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Premium User Ranking Card
            _buildUserRankCard(auth.username ?? 'Trader', myReturnPct, myNetWorth, myRank, myBadge, isDark),
            const SizedBox(height: 32),

            if (state.isLoading && entries.isEmpty)
              Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black))
            else if (state.error != null && entries.isEmpty)
              Center(child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
            else ...[
              if (entries.isNotEmpty) _buildPodium(entries, isDark),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Global Traders Directory',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Divider(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200, height: 1),
                    if (entries.length <= 3)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No additional traders found.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length - 3,
                        separatorBuilder: (context, index) => Divider(
                          color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final idx = index + 3;
                          final entry = entries[idx];
                          final isPositive = entry.totalReturnPercentage >= 0;

                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF111827) : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              entry.username,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(entry.totalPortfolioValue),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${isPositive ? "+" : ""}${entry.totalReturnPercentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(String username, double returnPct, double netWorth, String rank, String badge, bool isDark) {
    final isPositive = returnPct >= 0;
    final colorAccent = isPositive ? const Color(0xFFC5FF29) : const Color(0xFFEF4444);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Ranking",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Rank #$rank",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(color: colorAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  showDialog(
                    context: context,
                    builder: (context) => ShareCardModal(
                      username: username,
                      totalReturnPercentage: returnPct,
                      netWorth: netWorth,
                      rank: rank,
                      badge: badge,
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5FF29).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Color(0xFFC5FF29), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Net Worth", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(netWorth),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Total Return", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    "${isPositive ? "+" : ""}${returnPct.toStringAsFixed(2)}%",
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<dynamic> entries, bool isDark) {
    final len = entries.length;
    final first = len > 0 ? entries[0] : null;
    final second = len > 1 ? entries[1] : null;
    final third = len > 2 ? entries[2] : null;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final podiumWidth = width > 500 ? 150.0 : (width - 32) / 3;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _buildPodiumStep(
              username: second.username,
              value: currencyFormat.format(second.totalPortfolioValue),
              returns: '${second.totalReturnPercentage.toStringAsFixed(2)}%',
              placeText: '2nd Place',
              stepHeight: 120.0,
              stepColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
              badgeColor: const Color(0xFF94A3B8),
              stepWidth: podiumWidth,
              isDark: isDark,
            ),
          const SizedBox(width: 8),
          if (first != null)
            _buildPodiumStep(
              username: first.username,
              value: currencyFormat.format(first.totalPortfolioValue),
              returns: '${first.totalReturnPercentage.toStringAsFixed(2)}%',
              placeText: '1st Place',
              stepHeight: 160.0,
              stepColor: const Color(0xFFC5FF29).withOpacity(0.15),
              badgeColor: const Color(0xFFF59E0B),
              stepWidth: podiumWidth,
              isFirst: true,
              isDark: isDark,
            ),
          const SizedBox(width: 8),
          if (third != null)
            _buildPodiumStep(
              username: third.username,
              value: currencyFormat.format(third.totalPortfolioValue),
              returns: '${third.totalReturnPercentage.toStringAsFixed(2)}%',
              placeText: '3rd Place',
              stepHeight: 90.0,
              stepColor: isDark ? const Color(0xFF1F2937).withOpacity(0.6) : const Color(0xFFEDF2F7),
              badgeColor: const Color(0xFFB45309),
              stepWidth: podiumWidth,
              isDark: isDark,
            ),
        ],
      );
    });
  }

  Widget _buildPodiumStep({
    required String username,
    required String value,
    required String returns,
    required String placeText,
    required double stepHeight,
    required Color stepColor,
    required Color badgeColor,
    required double stepWidth,
    bool isFirst = false,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isFirst ? Icons.emoji_events : Icons.emoji_events_outlined,
          color: badgeColor,
          size: isFirst ? 40 : 30,
        ),
        const SizedBox(height: 8),
        Container(
          width: stepWidth,
          alignment: Alignment.center,
          child: Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
              fontSize: isFirst ? 16 : 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: stepWidth,
          alignment: Alignment.center,
          child: Text(
            returns,
            style: TextStyle(
              color: returns.startsWith('-') ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: stepWidth,
          height: stepHeight,
          decoration: BoxDecoration(
            color: stepColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                placeText,
                style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    value,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
