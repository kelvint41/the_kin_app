import 'package:flutter/material.dart';

/// Map pin visual with independent ownership badge chips above the pin.
class KinBusinessMapPinIcon extends StatelessWidget {
  const KinBusinessMapPinIcon({
    super.key,
    required this.isBlackOwned,
    required this.isVeteran,
    this.size = 56.0,
  });

  final bool isBlackOwned;
  final bool isVeteran;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pinSize = size * 0.72;
    final badgeHeight = size * 0.22;

    return SizedBox(
      width: size,
      height: size + (isBlackOwned || isVeteran ? badgeHeight : 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBlackOwned || isVeteran)
            SizedBox(
              height: badgeHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBlackOwned)
                    _MarkerBadge(
                      label: 'BO',
                      color: const Color(0xFF1A3A5C),
                      height: badgeHeight,
                    ),
                  if (isBlackOwned && isVeteran) const SizedBox(width: 2.0),
                  if (isVeteran)
                    _MarkerBadge(
                      label: 'VO',
                      color: const Color(0xFF2E5077),
                      height: badgeHeight,
                    ),
                ],
              ),
            ),
          Icon(
            Icons.location_on_rounded,
            size: pinSize,
            color: _pinColor(),
            shadows: const [
              Shadow(
                blurRadius: 4.0,
                color: Color(0x66000000),
                offset: Offset(0.0, 2.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _pinColor() {
    if (isBlackOwned && isVeteran) {
      return const Color(0xFFE87040);
    }
    if (isBlackOwned) {
      return const Color(0xFF1A3A5C);
    }
    if (isVeteran) {
      return const Color(0xFF2E5077);
    }
    return const Color(0xFF6B7C8F);
  }
}

class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({
    required this.label,
    required this.color,
    required this.height,
  });

  final String label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}
