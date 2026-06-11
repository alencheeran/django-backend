import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/leaderboard_provider.dart';

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

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(leaderboardProvider.notifier).fetchLeaderboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
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
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 32),

            if (state.isLoading && entries.isEmpty)
              const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            else if (state.error != null && entries.isEmpty)
              Center(child: Text(state.error!, style: const TextStyle(color: Color(0xFFEF4444))))
            else ...[
              // Podium Top 3 View
              if (entries.isNotEmpty) _buildPodium(entries),
              const SizedBox(height: 32),

              // Ranks directory table
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
                        'Global Traders Directory',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
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
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
                        itemBuilder: (context, index) {
                          final idx = index + 3; // Shift by 3 for podium
                          final entry = entries[idx];
                          final isPositive = entry.totalReturnPercentage >= 0;

                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF334155),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              entry.username,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(entry.totalPortfolioValue),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildPodium(List<dynamic> entries) {
    // Top 3 lists
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
          // 2nd Place (Silver)
          if (second != null)
            _buildPodiumStep(
              username: second.username,
              value: currencyFormat.format(second.totalPortfolioValue),
              returns: '${second.totalReturnPercentage.toStringAsFixed(2)}%',
              placeText: '2nd Place',
              stepHeight: 120.0,
              stepColor: const Color(0xFF334155),
              badgeColor: const Color(0xFF94A3B8),
              stepWidth: podiumWidth,
            ),
          const SizedBox(width: 8),
          // 1st Place (Gold)
          if (first != null)
            _buildPodiumStep(
              username: first.username,
              value: currencyFormat.format(first.totalPortfolioValue),
              returns: '${first.totalReturnPercentage.toStringAsFixed(2)}%',
              placeText: '1st Place',
              stepHeight: 160.0,
              stepColor: const Color(0xFF6366F1).withOpacity(0.3),
              badgeColor: const Color(0xFFF59E0B),
              stepWidth: podiumWidth,
              isFirst: true,
            ),
          const SizedBox(width: 8),
          // 3rd Place (Bronze)
          if (third != null)
            _buildPodiumStep(
              username: third.username,
              value: currencyFormat.format(third.totalPortfolioValue),
              returns: '${third.totalReturnPercentage.toStringAsFixed(2)}%',
              placeText: '3rd Place',
              stepHeight: 90.0,
              stepColor: const Color(0xFF334155),
              badgeColor: const Color(0xFFB45309),
              stepWidth: podiumWidth,
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
              color: Colors.white,
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
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                placeText,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
