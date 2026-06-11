import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_provider.dart';
import 'dashboard_view.dart';
import 'trade_view.dart';
import 'watchlist_view.dart';
import 'holdings_view.dart';
import 'transactions_view.dart';
import 'leaderboard_view.dart';
import 'settings_view.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    // Warm up WebSocket connection
    Future.microtask(() {
      ref.read(marketProvider.notifier).fetchNifty50AndWatchlist();
      ref.read(portfolioProvider.notifier).fetchPortfolioData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePage = ref.watch(activePageProvider);
    final portfolio = ref.watch(portfolioProvider);
    final auth = ref.watch(authProvider);

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.trending_up, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              _getPageTitle(activePage),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Capital Display
          if (!isMobile) ...[
            Center(
              child: Text(
                'Portfolio: ${currencyFormat.format(portfolio.totalPortfolioValue)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 16),
            Center(
              child: Text(
                'Cash: ${currencyFormat.format(portfolio.availableCash)}',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 24),
          ],
          // WebSocket live indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 6),
                Text('Live Stream', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile ? _buildDrawer(auth) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(activePage, auth),
          Expanded(
            child: _getBody(activePage),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavBar(activePage) : null,
    );
  }

  String _getPageTitle(ActivePage page) {
    switch (page) {
      case ActivePage.dashboard:
        return 'Dashboard';
      case ActivePage.trade:
        return 'Trade Room';
      case ActivePage.watchlist:
        return 'Watchlist';
      case ActivePage.holdings:
        return 'My Holdings';
      case ActivePage.history:
        return 'Transactions';
      case ActivePage.leaderboard:
        return 'Leaderboard';
      case ActivePage.settings:
        return 'Settings';
    }
  }

  Widget _getBody(ActivePage page) {
    switch (page) {
      case ActivePage.dashboard:
        return const DashboardView();
      case ActivePage.trade:
        return const TradeView();
      case ActivePage.watchlist:
        return const WatchlistView();
      case ActivePage.holdings:
        return const HoldingsView();
      case ActivePage.history:
        return const TransactionsView();
      case ActivePage.leaderboard:
        return const LeaderboardView();
      case ActivePage.settings:
        return const SettingsView();
    }
  }

  Widget _buildBottomNavBar(ActivePage activePage) {
    final Map<ActivePage, NavigationItem> navItems = {
      ActivePage.dashboard: NavigationItem(Icons.dashboard, 'Dashboard'),
      ActivePage.trade: NavigationItem(Icons.candlestick_chart, 'Trade'),
      ActivePage.watchlist: NavigationItem(Icons.star, 'Watch'),
      ActivePage.holdings: NavigationItem(Icons.card_travel, 'Holdings'),
    };

    final activeKeys = navItems.keys.toList();

    return BottomNavigationBar(
      currentIndex: activeKeys.indexOf(activePage).clamp(0, activeKeys.length - 1),
      onTap: (index) {
        ref.read(activePageProvider.notifier).state = activeKeys[index];
      },
      backgroundColor: const Color(0xFF1E293B),
      selectedItemColor: const Color(0xFF6366F1),
      unselectedItemColor: const Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      items: activeKeys.map((key) {
        final item = navItems[key]!;
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.title,
        );
      }).toList(),
    );
  }

  Widget _buildSidebar(ActivePage activePage, AuthState auth) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Color(0xFF334155))),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSidebarTile(ActivePage.dashboard, Icons.dashboard, 'Dashboard', activePage),
                _buildSidebarTile(ActivePage.trade, Icons.candlestick_chart, 'Trade Room', activePage),
                _buildSidebarTile(ActivePage.watchlist, Icons.star, 'Watchlist', activePage),
                _buildSidebarTile(ActivePage.holdings, Icons.card_travel, 'My Holdings', activePage),
                _buildSidebarTile(ActivePage.history, Icons.history, 'Transactions', activePage),
                _buildSidebarTile(ActivePage.leaderboard, Icons.emoji_events, 'Leaderboard', activePage),
                const Divider(color: Color(0xFF334155), height: 32),
                _buildSidebarTile(ActivePage.settings, Icons.settings, 'Settings', activePage),
              ],
            ),
          ),
          // Sidebar user profile footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  radius: 18,
                  child: Text(auth.username?.substring(0, 1).toUpperCase() ?? 'U'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        auth.username ?? 'Username',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text('Equities Trader', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    ref.read(marketProvider.notifier).disconnectWebSocket();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(ActivePage page, IconData icon, String title, ActivePage activePage) {
    final isSelected = page == activePage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        onTap: () {
          ref.read(activePageProvider.notifier).state = page;
        },
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
        leading: Icon(icon, color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthState auth) {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            accountName: Text(auth.username ?? 'Username', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('Equities Trader', style: TextStyle(color: Color(0xFF94A3B8))),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              child: Text(auth.username?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF94A3B8)),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.dashboard;
            },
          ),
          ListTile(
            leading: const Icon(Icons.candlestick_chart, color: Color(0xFF94A3B8)),
            title: const Text('Trade Room', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.trade;
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFF94A3B8)),
            title: const Text('Watchlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.watchlist;
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_travel, color: Color(0xFF94A3B8)),
            title: const Text('My Holdings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.holdings;
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF94A3B8)),
            title: const Text('Transactions', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.history;
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Color(0xFF94A3B8)),
            title: const Text('Leaderboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.leaderboard;
            },
          ),
          const Divider(color: Color(0xFF334155)),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF94A3B8)),
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.settings;
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            title: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444))),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              ref.read(marketProvider.notifier).disconnectWebSocket();
            },
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String title;
  NavigationItem(this.icon, this.title);
}
