import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../providers/theme_provider.dart';
import 'widgets/confetti_overlay.dart';

class DepositView extends ConsumerStatefulWidget {
  const DepositView({super.key});

  @override
  ConsumerState<DepositView> createState() => _DepositViewState();
}

class _DepositViewState extends ConsumerState<DepositView> with SingleTickerProviderStateMixin {
  String _amountText = "20423"; // Initial amount as in mockup (20.423)
  String _selectedBank = "Bank BCA";
  bool _isSuccess = false;
  double _swipeProgress = 0.0;
  bool _isSubmitting = false;

  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    if (_isSubmitting || _isSuccess) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (key == "back") {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
      } else if (key == ".") {
        if (!_amountText.contains(".")) {
          _amountText += ".";
        }
      } else {
        // Limit to 9 digits to avoid UI overflow
        if (_amountText.length < 9) {
          if (_amountText == "0") {
            _amountText = key;
          } else {
            _amountText += key;
          }
        }
      }
    });
  }

  String _formatAmount(String text) {
    if (text.isEmpty) return "0";
    
    try {
      final hasDecimal = text.contains(".");
      if (hasDecimal) {
        final parts = text.split(".");
        final integerPart = parts[0];
        final decimalPart = parts[1];
        
        final formattedInt = _formatInteger(integerPart);
        return "$formattedInt.$decimalPart";
      } else {
        return _formatInteger(text);
      }
    } catch (e) {
      return text;
    }
  }

  String _formatInteger(String text) {
    if (text.isEmpty) return "0";
    
    final reversedChars = text.split('').reversed.toList();
    final List<String> formattedReversed = [];
    
    for (int i = 0; i < reversedChars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formattedReversed.add('.');
      }
      formattedReversed.add(reversedChars[i]);
    }
    
    return formattedReversed.reversed.join('');
  }

  double get _numericAmount {
    if (_amountText.isEmpty) return 0.0;
    return double.tryParse(_amountText) ?? 0.0;
  }

  Future<void> _executeDeposit() async {
    if (_isSubmitting || _isSuccess) return;
    setState(() {
      _isSubmitting = true;
    });

    final amount = _numericAmount;
    if (amount <= 0) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount.')),
      );
      setState(() {
        _isSubmitting = false;
        _swipeProgress = 0.0;
      });
      return;
    }

    final result = await ref.read(portfolioProvider.notifier).depositCash(amount, _selectedBank);

    if (!mounted) return;

    if (result == null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSuccess = true;
        _isSubmitting = false;
      });
      _successController.forward();
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      setState(() {
        _isSubmitting = false;
        _swipeProgress = 0.0;
      });
    }
  }

  void _showBankSelector(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF131B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final banks = [
          {"name": "Bank BCA", "logo": "▲ BCA", "color": const Color(0xFF0F4C81)},
          {"name": "Bank Mandiri", "logo": "mandiri", "color": const Color(0xFF1C3F94)},
          {"name": "Bank BRI", "logo": "BRI", "color": const Color(0xFF005691)},
          {"name": "Bank BNI", "logo": "BNI", "color": const Color(0xFFE55300)},
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Bank Account",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...banks.map((bank) {
                final isSelected = _selectedBank == bank['name'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 60,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bank['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bank['logo'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    bank['name'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFFC5FF29))
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedBank = bank['name'] as String;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == AppThemeMode.dark;

    Widget body = ConfettiOverlay(
      showConfetti: _isSuccess,
      child: _isSuccess ? _buildSuccessView() : _buildDepositForm(isDark),
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
            child: body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: body,
    );
  }

  Widget _buildDepositForm(bool isDark) {
    return Column(
      children: [
        // Custom Top Header matching Screen 3 (Deposit)
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.black,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF161B2E),
                Color(0xFF0B0F1E),
              ],
            ),
          ),
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const Text(
                "Deposit",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Body Sheet (White/Dark Background with curved top corners)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Bank BCA Select Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 28,
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedBank,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showBankSelector(isDark),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF111827) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_note,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Display
                  Text(
                    "\$${_formatAmount(_amountText)}",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Dropdown subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Deposit In Dollars (\$)",
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          size: 12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Custom Numeric Keypad
                  _buildKeypad(isDark),

                  const SizedBox(height: 16),

                  // Swipe Slider Confirm Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildSwipeSlider(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad(bool isDark) {
    final keys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      [".", "0", "back"]
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: row.map((key) {
                final isBack = key == "back";
                final isSpecial = key == "." || key == "back";

                return GestureDetector(
                  onTap: () => _onKeyPress(key),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                     width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: isBack
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF374151) : Colors.grey.shade200,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                              size: 14,
                            ),
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 22,
                              fontWeight: isSpecial ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwipeSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSliderWidth = constraints.maxWidth;
        const buttonSize = 56.0;
        final maxOffset = maxSliderWidth - buttonSize - 8;

        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: (1.0 - (_swipeProgress / maxOffset)).clamp(0.0, 1.0),
                  child: const Text(
                    "Swipe to make a deposit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _swipeProgress,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isSubmitting || _isSuccess) return;
                    setState(() {
                      _swipeProgress = (_swipeProgress + details.delta.dx)
                          .clamp(0.0, maxOffset);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isSubmitting || _isSuccess) return;
                    if (_swipeProgress >= maxOffset * 0.9) {
                      setState(() {
                        _swipeProgress = maxOffset;
                      });
                      _executeDeposit();
                    } else {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _swipeProgress = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC5FF29), // Lime green accent
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessView() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFC5FF29),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.black, size: 56),
            ),
            const SizedBox(height: 32),
            const Text(
              "Deposit Successful!",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Successfully deposited \$${_formatAmount(_amountText)} to your available trading balance via $_selectedBank.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5FF29),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
