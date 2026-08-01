import '/components/feature_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'tier_card_model.dart';
export 'tier_card_model.dart';

class TierCardWidget extends StatefulWidget {
  const TierCardWidget({
    super.key,
    bool? isPro,
    bool? isElite,
    String? title,
    String? badgeLabel,
    String? price,
    String? f1,
    String? f2,
    String? f3,
    String? f4,
    this.beaconText,
    bool? isYearly,
    this.yearlyTeaser,
    this.valueTag,
    this.trialBannerText,
    this.trialCtaLabel,
    this.onStartTrial,
  })  : this.isPro = isPro ?? false,
        this.isElite = isElite ?? false,
        this.isYearly = isYearly ?? false,
        this.title = title ?? 'Community',
        this.badgeLabel = badgeLabel ?? 'Free Community Tier',
        this.price = price ?? '\$0',
        this.f1 = f1 ?? 'Access to public community forums',
        this.f2 = f2 ?? 'Basic business profile page on local directory',
        this.f3 = f3 ?? 'Up to 3 active local connections',
        this.f4 = f4 ?? 'Basic community support';

  final bool isPro;
  final bool isElite;
  final bool isYearly;
  final String title;
  final String badgeLabel;
  final String price;
  final String f1;
  final String f2;
  final String f3;
  final String f4;

  /// Cross-sell nudge shown under the price on the Monthly view (e.g. 'or
  /// $190/yr - 2 months free'). Pass null to hide it - the caller only
  /// supplies it when the Monthly tab is selected, since it would be
  /// redundant once the card is already showing the yearly price.
  final String? yearlyTeaser;

  /// Text shown on a small pulsing "beacon" badge at the card's top-left
  /// corner (e.g. 'Free' or 'Upgrade'). Null hides the beacon entirely.
  final String? beaconText;

  /// One-line value pitch shown under the badge and above the price (e.g.
  /// 'Get discovered.'). Null hides it entirely.
  final String? valueTag;

  /// Trial status line shown under the divider - either the countdown
  /// ('6 days left in your trial') or a reminder message once the nightly
  /// sweep has flagged one. Null hides it.
  final String? trialBannerText;

  /// Label for the trial button ('Start your 14-day trial', or the
  /// reminder CTA 'Keep my Founding Local tier'). Null hides the button -
  /// which is what happens once has_used_trial is true and the trial is
  /// no longer active.
  final String? trialCtaLabel;

  /// Tapped when [trialCtaLabel] is shown. The card is wrapped in an
  /// InkWell by its caller for the upgrade action, so this button stops
  /// propagation itself rather than relying on the parent.
  final Future<void> Function()? onStartTrial;

  @override
  State<TierCardWidget> createState() => _TierCardWidgetState();
}

class _TierCardWidgetState extends State<TierCardWidget>
    with SingleTickerProviderStateMixin {
  late TierCardModel _model;
  late AnimationController _beaconController;
  late Animation<double> _beaconOpacity;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TierCardModel());
    _beaconController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _beaconOpacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _beaconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _beaconController.dispose();
    _model.maybeDispose();

    super.dispose();
  }

  Widget _buildBeacon(BuildContext context) {
    // One colour for every beacon. They used to be theme.success for the
    // "Free" card and the brand gold for the "Upgrade" ones - two different
    // colours for the same element, and `success` is a dark forest green in
    // light mode against a mint in dark, so the Free badge also changed
    // identity between themes while the others did not.
    //
    // Gold in both, with black text: it is the badge colour used everywhere
    // else in the app and it holds on the light card and the dark elite card
    // alike.
    const beacon = Color(0xFFD4AF37);
    return FadeTransition(
      opacity: _beaconOpacity,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(10.0, 5.0, 10.0, 5.0),
        decoration: BoxDecoration(
          color: beacon,
          borderRadius: BorderRadius.circular(9999.0),
          boxShadow: [
            BoxShadow(
              color: beacon.withOpacity(0.6),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.0),
            Text(
              widget!.beaconText!,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                    color: Colors.black,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(24.0),
              shape: BoxShape.rectangle,
              border: Border.all(
                color: Colors.transparent,
                width: 0.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Container(
                child: Stack(
                  alignment: AlignmentDirectional(-1.0, -1.0),
                  children: [
                    if (valueOrDefault<bool>(
                      widget!.isElite,
                      false,
                    ))
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                            stops: [0.0, 1.0],
                            begin: AlignmentDirectional(1.0, 1.0),
                            end: AlignmentDirectional(-1.0, -1.0),
                          ),
                          shape: BoxShape.rectangle,
                        ),
                      ),
                    // The badge used to be PositionedDirectional(top: -8,
                    // start: -8) - anchored outside the card's own bounds at
                    // the top-left, which put it directly on top of the tier
                    // name. "Upgrade" sat across "Founding Local" and "Free"
                    // across "Community".
                    //
                    // It now sits in the layout above the title rather than
                    // floating over it, so it can never collide no matter how
                    // long a tier name gets, and it is aligned to the start so
                    // it reads as a label for the card rather than a sticker
                    // on the corner.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget!.beaconText != null)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 12.0),
                            child: Align(
                              alignment: AlignmentDirectional(-1.0, 0.0),
                              child: _buildBeacon(context),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  valueOrDefault<String>(
                                    widget!.title,
                                    'Community',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        color: widget!.isElite
                                            ? Color(0xFFD4AF37)
                                            : FlutterFlowTheme.of(context)
                                                .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: widget!.isElite
                                        ? Color(0x33D4AF37)
                                        : Color(0x00000000),
                                    borderRadius: BorderRadius.circular(9999.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 4.0, 16.0, 4.0),
                                    child: Container(
                                      child: Text(
                                        valueOrDefault<String>(
                                          widget!.badgeLabel,
                                          'Free Community Tier',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color: widget!.isElite
                                                  ? Color(0xFFD4AF37)
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget!.valueTag != null)
                                  Text(
                                    widget!.valueTag!,
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                          ),
                                          color: widget!.isElite
                                              ? Color(0xFFD4AF37)
                                              : FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .fontWeight,
                                          fontStyle: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                              ].divide(SizedBox(height: 4.0)),
                            ),
                            if (valueOrDefault<bool>(
                              widget!.isPro,
                              false,
                            ))
                              Container(
                                decoration: BoxDecoration(
                                  // Was primaryText - a text token used as a
                                  // pill fill, so this badge changed colour
                                  // with the body copy rather than staying a
                                  // badge. Brand gold with black text is the
                                  // pairing used everywhere else.
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(9999.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 4.0, 8.0, 4.0),
                                  child: Container(
                                    child: Text(
                                      'POPULAR',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: Colors.black,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget!.price,
                                '\$0',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Text(
                              widget!.isYearly ? '/ Year' : '/ Month',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.playfairDisplay(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ].divide(SizedBox(width: 4.0)),
                        ),
                        if (widget!.yearlyTeaser != null)
                          Text(
                            widget!.yearlyTeaser!,
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: widget!.isElite
                                      ? Color(0xFFD4AF37)
                                      : FlutterFlowTheme.of(context)
                                          .primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        Divider(
                          height: 16.0,
                          thickness: 1.0,
                          indent: 0.0,
                          endIndent: 0.0,
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            wrapWithModel(
                              model: _model.featureItemModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                // theme.primaryText, not theme.primary - this
                                // card's background is secondaryBackground,
                                // which flips (white/dark charcoal), and
                                // primary is a fixed dark green that read
                                // fine on white but vanished on dark
                                // charcoal. primaryText flips with the same
                                // surface, so it stays legible in both modes.
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primaryText,
                                benefit: valueOrDefault<String>(
                                  widget!.f1,
                                  'Access to public community forums',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                // theme.primaryText, not theme.primary - this
                                // card's background is secondaryBackground,
                                // which flips (white/dark charcoal), and
                                // primary is a fixed dark green that read
                                // fine on white but vanished on dark
                                // charcoal. primaryText flips with the same
                                // surface, so it stays legible in both modes.
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primaryText,
                                benefit: valueOrDefault<String>(
                                  widget!.f2,
                                  'Basic business profile page on local directory',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                // theme.primaryText, not theme.primary - this
                                // card's background is secondaryBackground,
                                // which flips (white/dark charcoal), and
                                // primary is a fixed dark green that read
                                // fine on white but vanished on dark
                                // charcoal. primaryText flips with the same
                                // surface, so it stays legible in both modes.
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primaryText,
                                benefit: valueOrDefault<String>(
                                  widget!.f3,
                                  'Up to 3 active local connections',
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.featureItemModel4,
                              updateCallback: () => safeSetState(() {}),
                              child: FeatureItemWidget(
                                // theme.primaryText, not theme.primary - this
                                // card's background is secondaryBackground,
                                // which flips (white/dark charcoal), and
                                // primary is a fixed dark green that read
                                // fine on white but vanished on dark
                                // charcoal. primaryText flips with the same
                                // surface, so it stays legible in both modes.
                                iconColor: widget!.isElite
                                    ? Color(0xFFD4AF37)
                                    : FlutterFlowTheme.of(context).primaryText,
                                benefit: valueOrDefault<String>(
                                  widget!.f4,
                                  'Basic community support',
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 8.0)),
                        ),
                        if (widget!.trialBannerText != null ||
                            widget!.trialCtaLabel != null)
                          _buildTrialSection(context),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrialSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent =
        widget!.isElite ? const Color(0xFFD4AF37) : theme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 8.0,
          thickness: 1.0,
          color: theme.alternate,
        ),
        if (widget!.trialBannerText != null)
          Text(
            widget!.trialBannerText!,
            style: theme.bodySmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              color: accent,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
              lineHeight: 1.4,
            ),
          ),
        if (widget!.trialCtaLabel != null)
          FFButtonWidget(
            onPressed: widget!.onStartTrial == null
                ? null
                : () async => await widget!.onStartTrial!(),
            text: widget!.trialCtaLabel!,
            options: FFButtonOptions(
              width: double.infinity,
              height: 44.0,
              color: accent,
              textStyle: theme.titleSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                // Black on gold/green in both themes - the fill is a fixed
                // brand colour, so a theme text token would invert against it.
                color: Colors.black,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
              elevation: 0.0,
              borderRadius: BorderRadius.circular(999.0),
            ),
          ),
      ].divide(SizedBox(height: 10.0)),
    );
  }
}
