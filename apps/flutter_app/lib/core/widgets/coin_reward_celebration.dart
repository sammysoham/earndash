import 'dart:async';
import 'package:flutter/material.dart';

Future<void> showCoinRewardCelebration(
  BuildContext context, {
  required int coins,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Coins earned',
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) => _CoinRewardCelebration(coins: coins),
  );
}

class _CoinRewardCelebration extends StatefulWidget {
  const _CoinRewardCelebration({required this.coins});

  final int coins;

  @override
  State<_CoinRewardCelebration> createState() => _CoinRewardCelebrationState();
}

class _CoinRewardCelebrationState extends State<_CoinRewardCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.easeOutBack.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final spec in _coinSpecs)
                  Transform.translate(
                    offset: Offset(
                      spec.dx * 120 * value,
                      spec.dy * 120 * value,
                    ),
                    child: Opacity(
                      opacity: (1 - _controller.value).clamp(0, 1),
                      child: Icon(
                        Icons.monetization_on_rounded,
                        color: const Color(0xFFFFD95E),
                        size: spec.size,
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: value,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102218),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4427FF87),
                          blurRadius: 32,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFFFD95E),
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '+${widget.coins} coins',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Reward received',
                          style: TextStyle(color: Color(0xFF98C7A7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _coinSpecs = <({double dx, double dy, double size})>[
  (dx: -0.8, dy: -0.4, size: 22),
  (dx: 0.75, dy: -0.5, size: 18),
  (dx: -0.55, dy: 0.55, size: 16),
  (dx: 0.55, dy: 0.45, size: 24),
  (dx: 0.1, dy: -0.8, size: 20),
];
