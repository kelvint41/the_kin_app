import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/services/local/favorites_local_store.dart';

/// Heart/bookmark toggle for a business, backed by [FavoritesLocalStore]
/// (device-local for now - see that file's doc comment for the plan to
/// back it with Firestore later).
///
/// Two visual modes:
/// - `onImageOverlay: true` (default) - a translucent white circle sitting
///   on top of a photo, matching the existing share button on the Business
///   Profile hero.
/// - `onImageOverlay: false` - a plain icon-only toggle for cards that sit
///   directly on `secondaryBackground` (Saved Places rows, listing cards).
class FavoriteHeartButton extends StatefulWidget {
  const FavoriteHeartButton({
    super.key,
    required this.businessId,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.onImageOverlay = true,
    this.onChanged,
  });

  final String businessId;
  final double size;
  final double iconSize;
  final bool onImageOverlay;
  final VoidCallback? onChanged;

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton> {
  final _store = FavoritesLocalStore.instance;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSaved = _store.isSaved(widget.businessId);
    final iconColor = isSaved
        ? theme.secondary
        : (widget.onImageOverlay ? Colors.white : theme.secondaryText);

    return Material(
      color:
          widget.onImageOverlay ? const Color(0x33FFFFFF) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.businessId.isEmpty
            ? null
            : () async {
                setState(() => _popped = true);
                await _store.toggle(widget.businessId);
                widget.onChanged?.call();
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _popped = false);
                });
              },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: AnimatedScale(
              scale: _popped ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Icon(
                isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: iconColor,
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
