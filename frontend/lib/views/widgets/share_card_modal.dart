import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareCardModal extends StatelessWidget {
  final String username;
  final double totalReturnPercentage;
  final double netWorth;
  final String rank;
  final String badge;

  const ShareCardModal({
    Key? key,
    required this.username,
    required this.totalReturnPercentage,
    required this.netWorth,
    required this.rank,
    required this.badge,
  }) : super(key: key);

  String _formatCurrency(double val) {
    final integerVal = val.toInt();
    final cents = ((val - integerVal) * 100).toInt().toString().padLeft(2, '0');
    final reversedChars = integerVal.toString().split('').reversed.toList();
    final List<String> formattedReversed = [];
    for (int i = 0; i < reversedChars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formattedReversed.add('.');
      }
      formattedReversed.add(reversedChars[i]);
    }
    return "\$${formattedReversed.reversed.join('')}.$cents";
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = totalReturnPercentage >= 0;
    final colorAccent = isPositive ? const Color(0xFFC5FF29) : const Color(0xFFEF4444);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(28.0),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 32,
                  spreadRadius: 8,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Share Return Card",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Glassmorphic Share Card Canvas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colorAccent.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Watermark & Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.trending_up, color: Colors.black, size: 14),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "ANTIGRAVITY TRADING",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(color: colorAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Large Return Box
                      const Text(
                        "TOTAL RETURN",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${isPositive ? "+" : ""}${totalReturnPercentage.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: colorAccent,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Username & Rank details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TRADER",
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "@$username",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "NET WORTH",
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(netWorth),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "GLOBAL RANK",
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "#$rank",
                                style: TextStyle(color: colorAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Share card actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.black),
                                  const SizedBox(width: 8),
                                  Text("Saved Card to Gallery! @$username rank #$rank"),
                                ],
                              ),
                              backgroundColor: colorAccent,
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 8),
                            Text("Save Image", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
