// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class KinBusinessMapPinIcon extends StatefulWidget {
  const KinBusinessMapPinIcon({
    super.key,
    this.width,
    this.height,
    this.isBlackOwned,
    this.isVeteranOwned,
  });

  final double? width;
  final double? height;
  final bool? isBlackOwned;
  final bool? isVeteranOwned;

  @override
  State<KinBusinessMapPinIcon> createState() => _KinBusinessMapPinIconState();
}

class _KinBusinessMapPinIconState extends State<KinBusinessMapPinIcon> {
  @override
  Widget build(BuildContext context) {
    // Safely treat blank database fields as false to stop the red screen crash
    final bool blackOwned = widget.isBlackOwned ?? false;
    final bool veteranOwned = widget.isVeteranOwned ?? false;

    // Sizing layout configurations
    final size = widget.width ?? 56.0;
    final pinSize = size * 0.72;
    final badgeHeight = size * 0.22;

    return SizedBox(
      width: size,
      height: size + (blackOwned || veteranOwned ? badgeHeight - 8.0 : 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blackOwned || veteranOwned)
            SizedBox(
              height: badgeHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (blackOwned)
                    _MarkerBadge(
                      label: 'BO',
                      color: const Color(0xFF1E1E1E),
                      height: badgeHeight,
                    ),
                  if (blackOwned && veteranOwned) const SizedBox(width: 2.0),
                  if (veteranOwned)
                    _MarkerBadge(
                      label: 'VO',
                      color: const Color(0xFF215973),
                      height: badgeHeight,
                    ),
                ],
              ),
            ),
          Icon(
            Icons.location_on_rounded,
            size: pinSize,
            color: (blackOwned && veteranOwned)
                ? const Color(0xFF8B5CF6) // Purple for dual identity
                : blackOwned
                    ? const Color(0xFF1E1E1E) // Black-Owned marker
                    : veteranOwned
                        ? const Color(0xFF215973) // Veteran-Owned marker
                        : const Color(0xFFEF4444), // Standard fallback red
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: height * 0.65,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
