import 'package:flutter/material.dart';

class EarndashBrand extends StatelessWidget {
  const EarndashBrand({
    super.key,
    this.compact = false,
    this.showWordmark = true,
  });

  final bool compact;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 44.0 : 58.0;
    final titleSize = compact ? 22.0 : 30.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            gradient: const LinearGradient(
              colors: [Color(0xFF00E676), Color(0xFF0F7A42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4400E676),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: compact ? 9 : 11,
                top: compact ? 12 : 14,
                child: Transform.rotate(
                  angle: -0.65,
                  child: Container(
                    width: compact ? 12 : 15,
                    height: compact ? 20 : 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF04110A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: compact ? 9 : 11,
                top: compact ? 10 : 12,
                child: Container(
                  width: compact ? 12 : 15,
                  height: compact ? 12 : 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB5FF73),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: compact ? 10 : 12,
                child: Container(
                  width: compact ? 18 : 22,
                  height: compact ? 6 : 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF04110A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EarnDash',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'earn • move • cash out',
                style: TextStyle(
                  color: Color(0xFF95B69F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
