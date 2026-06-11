class UserModel {
  final int id;
  final String username;
  final String email;
  final double balance;
  final double initialBalance;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.balance,
    required this.initialBalance,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      initialBalance: double.tryParse(json['initial_balance']?.toString() ?? '0') ?? 0.0,
    );
  }
}
