import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_provider.dart';
import '../providers/alert_provider.dart';
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

  void _showInAppAlertBanner(StockAlert alert, double price) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AlertBannerOverlay(
          alert: alert,
          currentPrice: price,
          onDismiss: () {
            entry.remove();
          },
        );
      },
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final activePage = ref.watch(activePageProvider);
    final portfolio = ref.watch(portfolioProvider);
    final auth = ref.watch(authProvider);

    // Listen to market price ticks and trigger alert matching
    ref.listen<MarketState>(marketProvider, (previous, next) {
      ref.read(alertProvider.notifier).checkAlerts(next, (alert, triggeredPrice) {
        HapticFeedback.vibrate();
        _showInAppAlertBanner(alert, triggeredPrice);
      });
    });

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: isMobile, // Let body extend under the floating bottom navigation bar
      appBar: isMobile
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _getPageTitle(activePage),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              actions: [
                // Capital Display
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
                    style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 24),
                // WebSocket live indicator
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Live Stream', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    final Map<ActivePage, IconData> navItems = {
      ActivePage.dashboard: Icons.home_outlined,
      ActivePage.holdings: Icons.description_outlined,
      ActivePage.trade: Icons.swap_horiz,
      ActivePage.history: Icons.access_time_outlined,
      ActivePage.settings: Icons.person_outline,
    };

    final activeKeys = navItems.keys.toList();

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 4),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: activeKeys.map((key) {
              final isSelected = activePage == key;
              final icon = navItems[key]!;

              return GestureDetector(
                onTap: () {
                  ref.read(activePageProvider.notifier).state = key;
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFC5FF29) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                    size: 24,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(ActivePage activePage, AuthState auth) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
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
                Divider(color: Theme.of(context).dividerColor, height: 32),
                _buildSidebarTile(ActivePage.settings, Icons.settings, 'Settings', activePage),
              ],
            ),
          ),
          // Sidebar user profile footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
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
        tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthState auth) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            accountName: Text(auth.username ?? 'Username', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: const Text('Equities Trader', style: TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Text(auth.username?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF64748B)),
            title: Text('Dashboard', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.dashboard;
            },
          ),
          ListTile(
            leading: const Icon(Icons.candlestick_chart, color: Color(0xFF64748B)),
            title: Text('Trade Room', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.trade;
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFF64748B)),
            title: Text('Watchlist', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.watchlist;
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_travel, color: Color(0xFF64748B)),
            title: Text('My Holdings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.holdings;
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF64748B)),
            title: Text('Transactions', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.history;
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Color(0xFF64748B)),
            title: Text('Leaderboard', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              ref.read(activePageProvider.notifier).state = ActivePage.leaderboard;
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF64748B)),
            title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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

class AlertBannerOverlay extends StatefulWidget {
  final StockAlert alert;
  final double currentPrice;
  final VoidCallback onDismiss;

  const AlertBannerOverlay({
    Key? key,
    required this.alert,
    required this.currentPrice,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<AlertBannerOverlay> createState() => _AlertBannerOverlayState();
}

class _AlertBannerOverlayState extends State<AlertBannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (_controller.isAnimating) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.alert.symbol;
    final isAbove = widget.alert.isAbove;
    final targetPrice = widget.alert.targetPrice;
    final price = widget.currentPrice;
    
    // Aesthetic colors matching our app
    final accentColor = isAbove ? const Color(0xFFC5FF29) : const Color(0xFFEF4444);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.95), // sleek slate/dark color
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accentColor.withOpacity(0.05),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bell icon with glow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAbove ? Icons.trending_up : Icons.trending_down,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Message details
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "ALERT TRIGGERED",
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "$symbol is now ₹${price.toStringAsFixed(2)} (Target: ₹${targetPrice.toStringAsFixed(2)})",
                            style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
