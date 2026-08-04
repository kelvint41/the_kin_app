import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/edit_exchange_post_sheet.dart';
import '/components/exchange_profile_sheet.dart';
import '/services/engagement_stats.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exchange_feed_item_model.dart';
export 'exchange_feed_item_model.dart';

/// One Exchange reaction: what it says, the glyph that says it, the Kindex
/// event_type it logs, and the theme color that carries its meaning (e.g.
/// money-green for a vouch, not just the uniform brand gold every reaction
/// used before).
class KinReaction {
  const KinReaction(this.eventType, this.label, this.icon, this.activeColor);

  final String eventType;
  final String label;
  final IconData icon;
  final Color Function(FlutterFlowTheme theme) activeColor;
}

/// The Exchange's reactions.
///
/// These replace ❤️ 🙌🏾 🔥 ✨ 👏🏾. Three things were wrong with that set.
/// It was Unicode emoji, so it rendered as Apple's and Google's artwork -
/// which is precisely why it looked borrowed from every other social app.
/// Two of the five hardcoded a skin tone, making a choice about identity
/// on behalf of every user who tapped them. And all five carried a Kindex
/// weight of 1, so they were five different ways of saying the same thing
/// to the scoring engine.
///
/// These are named for what someone means in a directory of businesses
/// rather than for a mood, and weighted by how strong a signal each is:
/// Backed is a vouch and worth five times a nod. Weights live in
/// kindex_config/scoring_weights, not here.
///
/// The old react_love/praise/fire/sparkle/applause weights are
/// deliberately left in that config. 19 UserEngagementEvents already carry
/// those types, and removing the weights would silently drop them out of
/// every score that has already counted them.
///
/// Icons are Material glyphs in the brand gold as an interim. Genuinely
/// distinctive marks need drawn artwork; swapping `icon` here is the only
/// change that takes, because nothing else refers to the glyph.
const kQuickReactions = <KinReaction>[
  // Money signal - the app's existing `success` token (a green tuned per
  // theme, not a hardcoded hex) rather than the shared brand gold every
  // reaction used before.
  KinReaction('react_backed', 'Backed', Icons.paid_rounded, _successColor),
  KinReaction('react_kin', 'Kin', Icons.diversity_3_rounded, _goldColor),
  // Craft/build signal - warm terracotta (accent3) instead of gold.
  KinReaction('react_built', 'Built', Icons.handyman_rounded, _accent3Color),
  KinReaction(
      'react_spotlight', 'Spotlight', Icons.highlight_rounded, _goldColor),
  KinReaction(
      'react_proud', 'Proud', Icons.military_tech_rounded, _goldColor),
];

Color _successColor(FlutterFlowTheme theme) => theme.success;
Color _goldColor(FlutterFlowTheme theme) => theme.accentOnSurface;
Color _accent3Color(FlutterFlowTheme theme) =>
    Color(theme.accent3.value).withAlpha(255);

class ExchangeFeedItemWidget extends StatefulWidget {
  const ExchangeFeedItemWidget({
    super.key,
    required this.postRecord,
    this.businessRef,
    this.authorDisplayName,
    this.authorPhotoUrl,
  });

  final ExchangePostsRecord postRecord;
  /// The business this post is tagged with, if any. Optional since the
  /// Exchange became a global feed: a customer with no business can post,
  /// and their post is tagged with nothing.
  final DocumentReference? businessRef;
  final String? authorDisplayName;
  final String? authorPhotoUrl;

  @override
  State<ExchangeFeedItemWidget> createState() => _ExchangeFeedItemWidgetState();
}

class _ExchangeFeedItemWidgetState extends State<ExchangeFeedItemWidget> {
  late ExchangeFeedItemModel _model;

  // Session-local only, mirroring RefinedPostWidget's _hasLiked: the
  // deterministic doc id below is the real source of truth for dedup
  // (a duplicate create is rejected server-side and silently ignored).
  final Set<String> _reactedEmoji = {};

  Future<void> _handleReaction(String emoji, String eventType) async {
    final userRef = currentUserReference;
    if (userRef == null || _reactedEmoji.contains(emoji)) {
      return;
    }
    setState(() => _reactedEmoji.add(emoji));
    final reactionRef = UserEngagementEventsRecord.collection.doc(
      '${userRef.id}_${widget.postRecord.reference.id}_$eventType',
    );
    try {
      await reactionRef.set(createUserEngagementEventsRecordData(
        userRef: userRef,
        businessRef: widget.businessRef,
        targetRef: widget.postRecord.reference,
        eventType: eventType,
        createdAt: getCurrentTimestamp,
      ));
    } catch (_) {
      // Duplicate reaction for this user+post+type — already counted.
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExchangeFeedItemModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Opens the tapped author's ExchangeProfileSheet. Only reachable when
  /// postRecord.userRef is non-null (both avatar and name InkWells are
  /// disabled otherwise), so the ! here is safe.
  void _openProfile(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: ExchangeProfileSheet(
          userRef: widget.postRecord.userRef!,
          fallbackName: widget.authorDisplayName,
          fallbackPhotoUrl: widget.authorPhotoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final postImage = widget.postRecord.postImage;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          0.0, 0.0, 0.0, theme.designToken.spacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    theme.designToken.spacing.lg,
                    theme.designToken.spacing.md,
                    theme.designToken.spacing.lg,
                    theme.designToken.spacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: widget.postRecord.userRef == null
                          ? null
                          : () => _openProfile(context),
                      borderRadius:
                          BorderRadius.circular(theme.designToken.radius.full),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            theme.designToken.radius.full),
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                theme.designToken.radius.full),
                            border:
                                Border.all(color: theme.divider, width: 1.0),
                          ),
                          // Was always the same hardcoded stock photo
                          // whenever authorPhotoUrl was null/empty (every
                          // post written before authorPhoto existed, plus
                          // any author who never set one) - now a real
                          // initials fallback instead of a stranger's face.
                          child: (widget.authorPhotoUrl ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  fadeInDuration: Duration(milliseconds: 0),
                                  fadeOutDuration: Duration(milliseconds: 0),
                                  imageUrl: widget.authorPhotoUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: (40.0 *
                                          MediaQuery.devicePixelRatioOf(
                                              context))
                                      .round(),
                                  memCacheHeight: (40.0 *
                                          MediaQuery.devicePixelRatioOf(
                                              context))
                                      .round(),
                                )
                              : Container(
                                  color: theme.secondaryBackground,
                                  alignment: Alignment.center,
                                  child: Text(
                                    businessInitials(valueOrDefault<String>(
                                        widget.authorDisplayName,
                                        'KIN Member')),
                                    style: theme.bodyMedium.override(
                                      font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold),
                                      color: theme.primaryText,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: theme.designToken.spacing.sm),
                    Expanded(
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: widget.postRecord.userRef == null
                            ? null
                            : () => _openProfile(context),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  valueOrDefault<String>(
                                    widget.authorDisplayName,
                                    'KIN Member',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodyMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    color: theme.primaryText,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                              if (widget.postRecord.userRef != null) ...[
                                SizedBox(width: theme.designToken.spacing.xs),
                                _KindexScoreBadge(
                                    userRef: widget.postRecord.userRef!),
                              ],
                            ],
                          ),
                          Text(
                            [
                              if (widget.postRecord.timestamp != null)
                                dateTimeFormat(
                                    'relative', widget.postRecord.timestamp!),
                              if (widget.postRecord.isEdited) 'edited',
                            ].join(' · '),
                            style: theme.labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: theme.hint,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                    if (widget.postRecord.userRef == currentUserReference)
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (context) => Padding(
                            padding: MediaQuery.viewInsetsOf(context),
                            child:
                                EditExchangePostSheet(postRecord: widget.postRecord),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.edit_outlined,
                              color: theme.secondaryText, size: 18.0),
                        ),
                      ),
                  ],
                ),
              ),
              if ((widget.postRecord.postText).isNotEmpty)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      theme.designToken.spacing.lg,
                      0.0,
                      theme.designToken.spacing.lg,
                      theme.designToken.spacing.sm),
                  child: Text(
                    widget.postRecord.postText,
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              if (postImage.isNotEmpty)
                ClipRRect(
                  child: CachedNetworkImage(
                    fadeInDuration: Duration(milliseconds: 0),
                    fadeOutDuration: Duration(milliseconds: 0),
                    imageUrl: postImage,
                    width: double.infinity,
                    height: 220.0,
                    fit: BoxFit.cover,
                    memCacheHeight:
                        (220.0 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    theme.designToken.spacing.lg,
                    theme.designToken.spacing.sm,
                    theme.designToken.spacing.lg,
                    theme.designToken.spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: kQuickReactions.map((reaction) {
                    final isActive =
                        _reactedEmoji.contains(reaction.eventType);
                    final activeColor = reaction.activeColor(theme);
                    return InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _handleReaction(
                          reaction.eventType, reaction.eventType),
                      child: AnimatedScale(
                        scale: isActive ? 1.15 : 1.0,
                        duration: Duration(milliseconds: 150),
                        child: Opacity(
                          opacity: isActive ? 1.0 : 0.55,
                          // Labelled, unlike the emoji it replaces. 'Backed'
                          // and 'Kin' mean something specific here and
                          // neither is guessable from a glyph alone.
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reaction.icon,
                                size: 22.0,
                                color:
                                    isActive ? activeColor : theme.secondaryText,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 2.0, 0.0, 0.0),
                                child: Text(
                                  reaction.label,
                                  style: theme.labelSmall.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                    fontSize: 10.0,
                                    color: isActive
                                        ? activeColor
                                        : theme.secondaryText,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact 'professional dashboard metric' pill, not the full KindexCardWidget
// (which is sized for a dashboard, not an inline feed row).
class _KindexScoreBadge extends StatelessWidget {
  const _KindexScoreBadge({required this.userRef});

  final DocumentReference userRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final scoreRef = KindexScoresRecord.collection.doc(userRef.id);
    return StreamBuilder<DocumentSnapshot>(
      stream: scoreRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox.shrink();
        }
        final scoreRecord = KindexScoresRecord.fromSnapshot(snapshot.data!);
        return Container(
          decoration: BoxDecoration(
            color: Color(0x1AFFD700),
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            border: Border.all(color: Color(0x4DFFD700), width: 1.0),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(6.0, 2.0, 6.0, 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  scoreRecord.isTrendingUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: scoreRecord.isTrendingUp
                      ? Color(0xFF10B981)
                      : Color(0xFFEF4444),
                  size: 10.0,
                ),
                Text(
                  scoreRecord.score.toStringAsFixed(0),
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
