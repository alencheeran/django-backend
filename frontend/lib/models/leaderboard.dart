class LeaderboardModel {
  final String username;
  final double totalPortfolioValue;
  final double totalReturnPercentage;

  LeaderboardModel({
    required this.username,
    required this.totalPortfolioValue,
    required this.totalReturnPercentage,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      username: json['username'] as String,
      totalPortfolioValue: double.tryParse(json['total_portfolio_value']?.toString() ?? '0') ?? 0.0,
      totalReturnPercentage: double.tryParse(json['total_return_percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}
