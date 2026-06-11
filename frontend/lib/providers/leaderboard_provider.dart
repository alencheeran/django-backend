import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard.dart';
import 'api_client.dart';

class LeaderboardState {
  final List<LeaderboardModel> entries;
  final bool isLoading;
  final String? error;

  LeaderboardState({
    required this.entries,
    required this.isLoading,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardModel>? entries,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;

  LeaderboardNotifier(this._ref)
      : super(LeaderboardState(
          entries: [],
          isLoading: false,
        ));

  Future<void> fetchLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);
    final client = _ref.read(apiClientProvider);

    try {
      final response = await client.request('/api/portfolio/leaderboard/', method: 'GET');

      if (response.statusCode == 200) {
        final List<dynamic> listJson = jsonDecode(response.body);
        final entries = listJson.map((x) => LeaderboardModel.fromJson(x)).toList();
        
        state = LeaderboardState(
          entries: entries,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to retrieve rankings. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network connectivity error fetching leaderboards.',
      );
    }
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});
