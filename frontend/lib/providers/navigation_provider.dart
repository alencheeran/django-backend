import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ActivePage { dashboard, trade, watchlist, holdings, history, leaderboard, settings }

final activePageProvider = StateProvider<ActivePage>((ref) => ActivePage.dashboard);
final activeStockSymbolProvider = StateProvider<String>((ref) => 'RELIANCE.NS');
