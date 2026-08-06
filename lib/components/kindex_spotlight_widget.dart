import 'dart:math';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_image_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/kin_services.dart';
import '/services/kindex_tiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kindex_spotlight_model.dart';
export 'kindex_spotlight_model.dart';

// A dedicated "prestige" palette for this widget only - a deep KIN green
// (not the neutral dark charcoal the card used before) with a warm gold
// accent, so the card reads as a trophy case rather than a generic dark
// panel. Deliberately not theme.tertiary/theme.primary: this card is meant
// to stand out from the rest of the page regardless of light/dark mode,
// the same reasoning power_hour_panel_widget.dart gives for its own
// hardcoded gold-on-dark-green surface.
const _kinGreenDark = Color(0xFF0F3A2C);
const _kinGreenDarker = Color(0xFF06140F);
const _gold = Color(0xFFF2C94C);
const _cream = Color(0xFFF4ECD8);
const _creamDim = Color(0xFFCFC4A6);
const _silver = Color(0xFFD8D8D8);
const _bronze = Color(0xFFD99A5B);
// Only used by the #1 celebration's firework particles - an ember accent
// alongside gold/cream so the bursts read as warm sparks, not a single
// flat color repeated.
const _ember = Color(0xFFFF6B4A);

/// 'KINDEX Spotlight' - a top-3-businesses-plus-top-3-customers leaderboard
/// card for The Exchange, redesigned per Kelvin's feedback: the previous
/// version fetched and could show up to 10 of each (a scroll to see them
/// all), styled as a plain dark card. This version caps both lists at 3 -
/// deliberately no scrolling anywhere, on the card or in the expanded
/// view - and leans into a bold "national ranking" trophy-case look:
/// medal-tinted podium tiers, a photo hero for #1, and a personalized
/// point-gap line to make the ranking feel worth chasing rather than just
/// informational.
///
/// Business Owners are ranked by their business's kindex_score; Customers
/// by their personal KindexScores.score - two separate scoring tracks
/// that already power the onboarding ticker (see
/// KinServices.fetchTopBusinessKindex / fetchTopCustomerKindex), reused
/// here rather than re-queried from scratch.
class KindexSpotlightWidget extends StatefulWidget {
  const KindexSpotlightWidget({super.key});

  @override
  State<KindexSpotlightWidget> createState() => _KindexSpotlightWidgetState();
}

class _KindexSpotlightWidgetState extends State<KindexSpotlightWidget> {
  late KindexSpotlightModel _model;

  bool _loading = true;
  List<KindexTickerEntry> _businessEntries = [];
  List<KindexTickerEntry> _customerEntries = [];

  /// The signed-in viewer's own score on whichever track they belong to
  /// (their business's kindex_score if they own one, else their personal
  /// KindexScores.score) - used only to compute the "N pts from #1" line.
  /// Null whenever it isn't available (logged out, no score doc yet, or
  /// the lookup failed) - the leaderboard itself must still render either
  /// way, so this is fetched best-effort and never blocks the rest of the
  /// load.
  double? _myScore;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KindexSpotlightModel());
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final businessResult = await KinServices.fetchTopBusinessKindex(limit: 3);
    final customerResult = await KinServices.fetchTopCustomerKindex(limit: 3);

    double? myScore;
    final ownedBusiness = currentUserDocument?.ownedBusiness;
    final isOwner = ownedBusiness != null;
    try {
      if (ownedBusiness != null) {
        final business = await BusinessesRecord.getDocumentOnce(ownedBusiness);
        myScore = business.kindexScore;
      } else if (currentUserReference != null) {
        final doc =
            await KindexScoresRecord.collection.doc(currentUserReference!.id).get();
        if (doc.exists) {
          myScore = KindexScoresRecord.fromSnapshot(doc).score;
        }
      }
    } catch (_) {
      // Personalization only - a failed lookup here should never keep the
      // leaderboard itself from rendering.
    }

    if (!mounted) return;
    setState(() {
      _businessEntries = businessResult.data ?? [];
      _customerEntries = customerResult.data ?? [];
      _myScore = myScore;
      _isOwner = isOwner;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _openLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => KindexSpotlightDetailSheet(
        businessEntries: _businessEntries,
        customerEntries: _customerEntries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KindexSpotlightCard(
      businessEntries: _businessEntries,
      customerEntries: _customerEntries,
      loading: _loading,
      isOwner: _isOwner,
      myScore: _myScore,
      onTap: _loading ? null : () => _openLeaderboard(context),
    );
  }
}

/// The compact preview card's presentation, pulled out of
/// [_KindexSpotlightWidgetState] as a plain StatelessWidget so it can be
/// rendered and screenshotted with hand-built sample data in a widget test
/// - the StatefulWidget's Firestore/auth-backed data loading otherwise
/// makes it impossible to render this in isolation.
class KindexSpotlightCard extends StatelessWidget {
  const KindexSpotlightCard({
    super.key,
    required this.businessEntries,
    required this.customerEntries,
    required this.loading,
    required this.isOwner,
    required this.myScore,
    required this.onTap,
  });

  final List<KindexTickerEntry> businessEntries;
  final List<KindexTickerEntry> customerEntries;
  final bool loading;
  final bool isOwner;
  final double? myScore;
  final VoidCallback? onTap;

  /// "Only N pts from #1 this week" (or a #1 callout if the viewer already
  /// leads), personalized to whichever track the signed-in viewer competes
  /// on. Null when there's nothing to personalize with.
  String? _gapToFirstCta() {
    if (myScore == null) return null;
    final topEntries = isOwner ? businessEntries : customerEntries;
    if (topEntries.isEmpty) return null;
    final gap = topEntries.first.score - myScore!;
    if (gap <= 0) return "You're #1 this week";
    return 'Only ${gap.round()} pts from #1 this week';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final gapCta = _gapToFirstCta();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(theme.designToken.spacing.lg, 0.0,
          theme.designToken.spacing.lg, theme.designToken.spacing.lg),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kinGreenDark, _kinGreenDarker],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            border: Border.all(color: _gold.withAlpha(0x48), width: 1.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.designToken.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 18.0)),
                    SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        'KINDEX SPOTLIGHT',
                        style: theme.labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Text(
                        'NATIONAL RANKING',
                        style: theme.labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                          color: _kinGreenDarker,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.0,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.0),
                Text(
                  "San Antonio's top KINDEX earners this week",
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(),
                    color: _creamDim,
                    letterSpacing: 0.0,
                  ),
                ),
                SizedBox(height: theme.designToken.spacing.md),
                if (loading)
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: theme.designToken.spacing.md),
                    child: Text(
                      'Loading leaderboard...',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: _creamDim,
                        letterSpacing: 0.0,
                      ),
                    ),
                  )
                else ...[
                  if (businessEntries.isNotEmpty) ...[
                    _sectionLabel('Top businesses'),
                    SizedBox(height: 10.0),
                    _Podium(entries: businessEntries),
                    SizedBox(height: theme.designToken.spacing.md),
                  ],
                  if (customerEntries.isNotEmpty) ...[
                    _sectionLabel('Top members'),
                    SizedBox(height: 8.0),
                    _MemberChipRow(entries: customerEntries),
                  ],
                  if (businessEntries.isEmpty && customerEntries.isEmpty)
                    Text(
                      'No ranked members yet.',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: _creamDim,
                        letterSpacing: 0.0,
                      ),
                    ),
                ],
                if (!loading &&
                    (businessEntries.isNotEmpty || customerEntries.isNotEmpty)) ...[
                  SizedBox(height: theme.designToken.spacing.md),
                  Row(
                    children: [
                      if (gapCta != null)
                        Expanded(
                          child: Text(
                            gapCta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                              color: _creamDim,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.0,
                            ),
                          ),
                        )
                      else
                        Spacer(),
                      Text(
                        'See full ranking →',
                        style: theme.labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      )
          .animate(delay: 150.ms)
          .shimmer(duration: 1200.ms, color: _gold.withAlpha(0x33)),
    );
  }
}

Widget _sectionLabel(String label) => Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            color: _creamDim,
            fontWeight: FontWeight.bold,
            fontSize: 11.0,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(width: 8.0),
        Expanded(
          child: Divider(color: _cream.withAlpha(0x24), thickness: 1.0, height: 1.0),
        ),
      ],
    );

/// Top-3 business podium: rank 1 centered, elevated, and a full photo
/// hero; 2 and 3 flank it as smaller medal-tinted tiles. Handles fewer
/// than 3 entries gracefully (a business with no ranked competitors yet
/// still gets its own gold slot rather than an empty podium).
class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<KindexTickerEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Reorder so index 1 (rank 1) renders centered: [2nd, 1st, 3rd].
    final order = <int>[
      if (entries.length > 1) 1,
      0,
      if (entries.length > 2) 2,
    ];
    final championSlot = order.indexOf(0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Slots are equal-width Expanded children of the Row below, so the
        // champion's horizontal center is just its slot index - no need
        // for a GlobalKey/RenderBox lookup to find it.
        final slotWidth = constraints.maxWidth / order.length;
        final championX = slotWidth * (championSlot + 0.5);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  order.map((i) => _PodiumSlot(rank: i, entry: entries[i])).toList(),
            ),
            // Positioned above the Row rather than inside _PodiumSlot so a
            // burst can radiate past the #1 card's own edges toward #2/#3,
            // matching the approved "Grand Finale" mockup's scale - a
            // fireworks layer scoped to just the champion's own card read
            // as too small and contained when tried during design.
            IgnorePointer(
              child: SizedBox(
                width: constraints.maxWidth,
                // Tall enough to cover the #1 card's avatar/name area
                // without stretching over the whole podium's height - see
                // _ChampionFireworks' originY comment for how this number
                // was derived.
                height: 170.0,
                child: _ChampionFireworks(originX: championX, originY: 78.0),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.rank, required this.entry});

  /// 0-indexed: 0 = gold, 1 = silver, 2 = bronze.
  final int rank;
  final KindexTickerEntry entry;

  static const _medalColors = [_gold, _silver, _bronze];

  @override
  Widget build(BuildContext context) {
    final medal = _medalColors[rank];
    final isFirst = rank == 0;
    final avatarSize = isFirst ? 60.0 : 44.0;
    final initial =
        entry.name.trim().isNotEmpty ? entry.name.trim()[0].toUpperCase() : '?';

    return Expanded(
      child: GestureDetector(
        onTap: entry.businessRef == null
            ? null
            : () => context.pushNamed(
                  BusinessProfileV2Widget.routeName,
                  queryParameters: {
                    'businessDocument': serializeParam(
                      entry.businessRef,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                ),
        child: Padding(
          padding: EdgeInsets.only(
            top: isFirst ? 0.0 : 16.0,
            left: 3.0,
            right: 3.0,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 6.0, vertical: isFirst ? 12.0 : 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [medal.withAlpha(isFirst ? 0x38 : 0x22), medal.withAlpha(0x08)],
              ),
              border: Border.all(color: medal.withAlpha(isFirst ? 0x8C : 0x59)),
              boxShadow: isFirst
                  ? [BoxShadow(color: _gold.withAlpha(0x40), blurRadius: 16.0, spreadRadius: 1.0)]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${rank + 1}',
                  style: TextStyle(
                    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                    color: medal,
                    fontWeight: FontWeight.w800,
                    fontSize: isFirst ? 30.0 : 22.0,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 6.0),
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1AFFFFFF),
                    border: Border.all(color: medal, width: 2.0),
                  ),
                  alignment: Alignment.center,
                  // #1 shows the business's actual photo - BusinessImage's
                  // own fallback (the KIN logo) covers a missing/broken
                  // heroImage for free. #2/#3 keep the initials ring.
                  child: isFirst
                      ? ClipOval(
                          child: BusinessImage(
                            imageUrl: entry.heroImage,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          initial,
                          style: TextStyle(
                            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                            color: _cream,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                ),
                SizedBox(height: 8.0),
                Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                    color: _cream,
                    fontWeight: FontWeight.w700,
                    fontSize: isFirst ? 13.0 : 12.0,
                  ),
                ),
                SizedBox(height: 4.0),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: medal.withAlpha(0x26),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    entry.score.toStringAsFixed(0),
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: medal,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.0,
                    ),
                  ),
                ),
                if (isFirst) ...[
                  SizedBox(height: 4.0),
                  Text(
                    '#1 in San Antonio',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The #1 slot's one-time celebration: a pulsing gold halo behind the
/// avatar plus three staggered firework bursts (left, right, center) -
/// the "Grand Finale" style Kelvin picked from an HTML mockup published
/// as an Artifact before this was written (see kin-app-exchange-roadmap
/// memory for the approval). Plays once when the podium first mounts,
/// driven by a single AnimationController + CustomPainter rather than a
/// manual per-frame particle simulation - each particle's position is a
/// closed-form function of elapsed time, so nothing needs mutable state
/// updated every tick.
///
/// Unlike the mockup's canvas version, bursts appear directly at their
/// explosion point rather than traveling there first via a rising rocket
/// trail - simpler, and avoids any particle needing to travel outside the
/// podium's own layout bounds.
class _ChampionFireworks extends StatefulWidget {
  const _ChampionFireworks({required this.originX, required this.originY});

  /// Center of the #1 avatar, in the overlay's local coordinate space.
  /// originX is computed exactly by [_Podium] from the champion's slot
  /// index; originY is a fixed estimate (card top-padding 12 + rank digit
  /// ~30 + gap 6 + half the 60px avatar = 78) since the #1 card is always
  /// the tallest podium tile and so always defines the Row's top edge -
  /// close enough for a decorative burst, not meant to be pixel-exact.
  final double originX;
  final double originY;

  @override
  State<_ChampionFireworks> createState() => _ChampionFireworksState();
}

class _ChampionFireworksState extends State<_ChampionFireworks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Burst> _bursts;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    final random = Random();
    _bursts = [
      _Burst.at(widget.originX - 34, widget.originY - 6,
          startFraction: 0.0, random: random),
      _Burst.at(widget.originX + 36, widget.originY - 2,
          startFraction: 0.16, random: random),
      _Burst.at(widget.originX, widget.originY - 16,
          startFraction: 0.34, random: random, particleCount: 30),
    ];
    // The controller itself is just a 0..1 numeric driver, not motion by
    // itself - it always runs. MediaQuery.disableAnimations (the OS-level
    // "reduce motion" setting, Settings > Accessibility on both iOS and
    // Android) instead switches what the painter draws each frame, from
    // moving particles to a single fade-in-fade-out glow. Read fresh in
    // build() below rather than cached here, so a mid-flight setting
    // change (rare, but free to handle) still lands correctly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _FireworksPainter(
          progress: _controller.value,
          originX: widget.originX,
          originY: widget.originY,
          bursts: _bursts,
          // Reduced-motion visitors get a single soft glow pulse instead
          // of moving particles - still needs *a* controller to animate,
          // so this reuses the same one rather than adding a second.
          reducedMotionGlow: reducedMotion,
        ),
      ),
    );
  }
}

class _Burst {
  _Burst({
    required this.x,
    required this.y,
    required this.startFraction,
    required this.particles,
  });

  final double x;
  final double y;

  /// Fraction (0..1) of the parent controller's total duration at which
  /// this burst's particles start expanding.
  final double startFraction;
  final List<_Particle> particles;

  /// Builds a burst with randomized-but-seeded-once particle directions -
  /// randomness only ever runs at construction time (in initState), never
  /// inside paint(), so repeated frames stay deterministic.
  factory _Burst.at(
    double x,
    double y, {
    required double startFraction,
    required Random random,
    int particleCount = 22,
  }) {
    const colors = [_gold, _cream, _ember];
    final particles = List.generate(particleCount, (i) {
      final angle = (2 * pi * i / particleCount) + random.nextDouble() * 0.4;
      return _Particle(
        angle: angle,
        speed: 55 + random.nextDouble() * 55,
        color: colors[i % colors.length],
        size: 2.0 + random.nextDouble() * 1.6,
        life: 0.32 + random.nextDouble() * 0.16,
      );
    });
    return _Burst(x: x, y: y, startFraction: startFraction, particles: particles);
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.life,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;

  /// Fraction of the *controller's* total duration this particle stays
  /// visible for, counting from its burst's startFraction.
  final double life;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter({
    required this.progress,
    required this.originX,
    required this.originY,
    required this.bursts,
    required this.reducedMotionGlow,
  });

  final double progress;
  final double originX;
  final double originY;
  final List<_Burst> bursts;
  final bool reducedMotionGlow;

  @override
  void paint(Canvas canvas, Size size) {
    if (reducedMotionGlow) {
      _paintReducedMotionGlow(canvas);
      return;
    }
    _paintHalo(canvas);
    for (final burst in bursts) {
      final local = progress - burst.startFraction;
      if (local <= 0) continue;
      for (final particle in burst.particles) {
        final t = (local / particle.life).clamp(0.0, 1.0);
        if (t >= 1.0) continue;
        // Decelerating radial travel (eased) plus a light downward drift
        // that grows with time, so particles read as falling embers by
        // the end of their life rather than flying in a straight line.
        final eased = 1 - pow(1 - t, 2).toDouble();
        final dx = cos(particle.angle) * particle.speed * eased * 0.9;
        final dy = sin(particle.angle) * particle.speed * eased * 0.9 + 40 * t * t;
        final alpha = (1 - t).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = particle.color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
        canvas.drawCircle(
          Offset(burst.x + dx, burst.y + dy),
          particle.size * (1 - t * 0.3),
          paint,
        );
      }
    }
  }

  /// Two ring pulses behind the avatar, synced with the first and center
  /// bursts, so the celebration reads as radiating from the champion
  /// rather than floating above them.
  void _paintHalo(Canvas canvas) {
    for (final haloStart in [0.0, 0.34]) {
      final local = ((progress - haloStart) / 0.32).clamp(0.0, 1.0);
      if (progress < haloStart || local >= 1.0) continue;
      final radius = 22 + local * 46;
      final alpha = (1 - local) * 0.5;
      final paint = Paint()
        ..color = _gold.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(originX, originY), radius, paint);
    }
  }

  /// A single static glow, no travelling particles - fades in then back
  /// out once over the same duration the full celebration would otherwise
  /// play for, rather than a constant/permanent decoration.
  void _paintReducedMotionGlow(Canvas canvas) {
    final envelope = (sin(pi * progress.clamp(0.0, 1.0))).clamp(0.0, 1.0);
    if (envelope <= 0.02) return;
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.4 * envelope)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);
    canvas.drawCircle(Offset(originX, originY), 42.0, paint);
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotionGlow != reducedMotionGlow;
}

/// Up to 3 compact side-by-side chips for the top customers - simpler than
/// the business podium (no photos to show for customers anywhere in the
/// app), but still medal-colored so the two sections read as one
/// consistent ranking rather than two different visual languages.
class _MemberChipRow extends StatelessWidget {
  const _MemberChipRow({required this.entries});

  final List<KindexTickerEntry> entries;

  static const _medalColors = [_gold, _silver, _bronze];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: entries.asMap().entries.map((indexed) {
        final rank = indexed.key;
        final entry = indexed.value;
        final medal = _medalColors[rank];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: rank == entries.length - 1 ? 0.0 : 8.0),
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _cream.withAlpha(0x0D),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: _cream.withAlpha(0x1A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26.0,
                    height: 26.0,
                    decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                        color: _kinGreenDarker,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.0),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                            color: _cream,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0,
                          ),
                        ),
                        Text(
                          '${entry.score.toStringAsFixed(0)} pts',
                          style: TextStyle(
                            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                            color: _gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// The tap-to-expand detail view: fixed-size (never scrolls - both lists
/// are already capped at 3), a hero row for the #1 business, then plain
/// rank rows for whatever else is ranked. A regular showModalBottomSheet
/// rather than the old DraggableScrollableSheet, since there's no longer
/// enough content for dragging/scrolling to do anything.
class KindexSpotlightDetailSheet extends StatelessWidget {
  const KindexSpotlightDetailSheet({
    required this.businessEntries,
    required this.customerEntries,
  });

  final List<KindexTickerEntry> businessEntries;
  final List<KindexTickerEntry> customerEntries;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final topBusiness = businessEntries.isNotEmpty ? businessEntries.first : null;
    final restBusinesses = businessEntries.length > 1 ? businessEntries.sublist(1) : const <KindexTickerEntry>[];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kinGreenDark, _kinGreenDarker],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.designToken.radius.lg),
          topRight: Radius.circular(theme.designToken.radius.lg),
        ),
        border: Border(top: BorderSide(color: _gold.withAlpha(0x48), width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  margin: EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: _cream.withAlpha(0x33),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              Row(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 18.0)),
                  SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      'KINDEX SPOTLIGHT',
                      style: TextStyle(
                        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                        color: _gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: Text(
                      'NATIONAL RANKING',
                      style: TextStyle(
                        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                        color: _kinGreenDarker,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (topBusiness == null && businessEntries.isEmpty && customerEntries.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: Text(
                    'No ranked members yet.',
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: _creamDim,
                    ),
                  ),
                ),
              if (topBusiness != null) ...[
                SizedBox(height: 16.0),
                _HeroRow(entry: topBusiness),
              ],
              if (restBusinesses.isNotEmpty || businessEntries.isNotEmpty) ...[
                SizedBox(height: 18.0),
                _sectionLabel('Top businesses'),
                ...restBusinesses.asMap().entries.map((indexed) => _DetailRow(
                      rank: indexed.key + 2,
                      entry: indexed.value,
                      tappable: true,
                    )),
              ],
              if (customerEntries.isNotEmpty) ...[
                SizedBox(height: 18.0),
                _sectionLabel('Top members'),
                ...customerEntries.asMap().entries.map((indexed) => _DetailRow(
                      rank: indexed.key + 1,
                      entry: indexed.value,
                      tappable: false,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroRow extends StatelessWidget {
  const _HeroRow({required this.entry});

  final KindexTickerEntry entry;

  @override
  Widget build(BuildContext context) {
    final tier = kindexTierForScore(entry.score);
    return GestureDetector(
      onTap: entry.businessRef == null
          ? null
          : () => context.pushNamed(
                BusinessProfileV2Widget.routeName,
                queryParameters: {
                  'businessDocument': serializeParam(
                    entry.businessRef,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              ),
      child: Container(
        padding: EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gold.withAlpha(0x2E), _gold.withAlpha(0x05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _gold.withAlpha(0x66)),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            ClipOval(
              child: BusinessImage(
                imageUrl: entry.heroImage,
                width: 58.0,
                height: 58.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 14.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: _cream,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    '#1 business · San Antonio',
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                    color: _gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 22.0,
                    height: 1.0,
                  ),
                ),
                if (tier != null)
                  Text(
                    tier.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: _creamDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.0,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.rank,
    required this.entry,
    required this.tappable,
  });

  final int rank;
  final KindexTickerEntry entry;

  /// Businesses link to their profile; customers have no profile page to
  /// link to, same as every earlier version of this widget.
  final bool tappable;

  static const _medalColors = [_gold, _silver, _bronze];

  @override
  Widget build(BuildContext context) {
    final medal = _medalColors[(rank - 1).clamp(0, 2)];
    final initial =
        entry.name.trim().isNotEmpty ? entry.name.trim()[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: !tappable || entry.businessRef == null
          ? null
          : () => context.pushNamed(
                BusinessProfileV2Widget.routeName,
                queryParameters: {
                  'businessDocument': serializeParam(
                    entry.businessRef,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 20.0,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                  color: _creamDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
            SizedBox(width: 10.0),
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                  color: _kinGreenDarker,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.0,
                ),
              ),
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                  color: _cream,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
            Text(
              entry.score.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                color: _gold,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
