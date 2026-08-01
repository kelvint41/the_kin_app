import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/kin_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGold = Color(0xFFD4AF37);

const Map<String, String> _kRewardLabels = {
  'POWER_HOUR': '1-Hour Power Hour Boost',
  'GLOWING_PIN': '24-Hour Glowing Map Pin',
  'TIER_FOUNDING_LOCAL': 'Founding Local Tier — 1 Month Free',
  'TIER_PRO_GROWTH': 'Pro Growth Tier — 1 Month Free',
  'TIER_ELITE_GROWTH': 'Elite Growth Tier — Free',
};

/// Owner-dashboard panel for the mystery reward system. Streams the
/// signed-in owner's most recent un-redeemed `unlocked_rewards` doc; shows
/// nothing when there isn't one. Unrevealed rewards get a scratch-off
/// mystery-box reveal (hand-built - no confetti/lottie package in this app,
/// following the staggered AnimationController approach from
/// kin_splash_widget.dart), then settle into a countdown + "Claim Reward"
/// panel, mirroring the Timer.periodic pattern in power_hour_panel_widget.
class MysteryRewardPanelWidget extends StatefulWidget {
  const MysteryRewardPanelWidget({super.key, required this.businessRef});

  final DocumentReference businessRef;

  @override
  State<MysteryRewardPanelWidget> createState() =>
      _MysteryRewardPanelWidgetState();
}

class _MysteryRewardPanelWidgetState extends State<MysteryRewardPanelWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _reveal(UnlockedRewardsRecord reward) async {
    if (_revealController.isAnimating) return;
    await _revealController.forward(from: 0.0);
    await reward.reference.update({'reveal_animation_shown': true});
  }

  Future<void> _redeem(UnlockedRewardsRecord reward) async {
    final result =
        await KinServices.redeemReward(rewardId: reward.reference.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.isSuccess
          ? 'Reward redeemed! Check your dashboard for the update.'
          : result.error ?? 'Could not redeem this reward.'),
    ));
  }

  String _formatRemaining(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    if (days > 0) return '$days d ${hours}h left';
    final minutes = remaining.inMinutes % 60;
    return '${remaining.inHours}h ${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final userRef = currentUserReference;
    if (userRef == null) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);

    return StreamBuilder<List<UnlockedRewardsRecord>>(
      stream: queryUnlockedRewardsRecord(
        queryBuilder: (q) => q
            .where('user_ref', isEqualTo: userRef)
            .where('is_redeemed', isEqualTo: false)
            .orderBy('date_won', descending: true),
        limit: 1,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final reward = snapshot.data!.first;
        final expiresAt = reward.expirationDate;
        final isExpired =
            expiresAt != null && expiresAt.isBefore(DateTime.now());

        return Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: _kGold.withAlpha(140), width: 1.0),
          ),
          padding: const EdgeInsets.all(20.0),
          child: reward.revealAnimationShown
              ? _buildRewardCard(theme, reward, expiresAt, isExpired)
              : _buildScratchOff(theme, reward),
        );
      },
    );
  }

  Widget _buildScratchOff(FlutterFlowTheme theme, UnlockedRewardsRecord reward) {
    return GestureDetector(
      onTap: () => _reveal(reward),
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, _) {
          final t = _revealController.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * t,
                      child: Icon(Icons.card_giftcard_rounded,
                          color: _kGold, size: 56.0),
                    ),
                  ),
                  Opacity(
                    opacity: 1 - t,
                    child: Container(
                      width: 88.0,
                      height: 88.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [_kGold.withAlpha(230), _kGold.withAlpha(90)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '?',
                        style: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                t == 0
                    ? 'Milestone reached! Tap to reveal your mystery reward.'
                    : (_kRewardLabels[reward.rewardType] ?? reward.rewardType),
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardCard(
    FlutterFlowTheme theme,
    UnlockedRewardsRecord reward,
    DateTime? expiresAt,
    bool isExpired,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: _kGold, size: 20.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                _kRewardLabels[reward.rewardType] ?? reward.rewardType,
                style: theme.titleSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          expiresAt == null
              ? ''
              : (isExpired ? 'Expired' : _formatRemaining(expiresAt)),
          style: theme.bodySmall.override(
            color: isExpired ? theme.secondaryText : _kGold,
          ),
        ),
        const SizedBox(height: 14.0),
        FFButtonWidget(
          onPressed: isExpired ? null : () => _redeem(reward),
          text: isExpired ? 'Expired' : 'Claim Reward',
          icon: isExpired
              ? null
              : const Icon(Icons.redeem_rounded, size: 18.0),
          options: FFButtonOptions(
            width: double.infinity,
            height: 44.0,
            color: isExpired ? theme.alternate : _kGold,
            textStyle: theme.titleSmall.override(
              color: isExpired ? theme.secondaryText : Colors.black,
            ),
            elevation: 0.0,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }
}
