import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/create_promotion_sheet.dart';
import '/components/edit_exchange_post_sheet.dart';
import '/components/exchange_profile_sheet.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/engagement_stats.dart';
import '/components/kindex_tier_badge_widget.dart';
import '/services/exchange_post_types.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:async';
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

/// Reaction types that can earn notable_reaction amplification server-side
/// (see exchange_reaction_counts.js) - a vouch and the app's own name for
/// itself, mirrored here so the client only ever renders the highlight
/// line for the same two types the Cloud Function actually stamps.
const _kAmplifyingEventTypes = {'react_backed', 'react_spotlight'};

/// Leading phrase for the amplification line, per eventType - the caller
/// appends 'by {name}' itself (e.g. 'Backed by {name}'). Falls back to a
/// generic phrase for any other value rather than throwing, though in
/// practice only _kAmplifyingEventTypes reach this.
String _amplifyingLabel(String eventType) => switch (eventType) {
      'react_backed' => 'Backed',
      'react_spotlight' => 'Spotlighted',
      _ => 'Noticed',
    };

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

  // Restored on load from UserEngagementEvents (see _restoreReactedState)
  // and updated optimistically on tap - the deterministic doc id below is
  // the real source of truth for dedup either way (a duplicate create is
  // rejected server-side and silently ignored), this is just what the UI
  // reads to decide each icon's active state.
  final Set<String> _reactedEmoji = {};

  Future<void> _handleReaction(String eventType) async {
    final userRef = currentUserReference;
    if (userRef == null || _reactedEmoji.contains(eventType)) {
      return;
    }
    setState(() => _reactedEmoji.add(eventType));
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

  /// Restores which of this post's 5 reactions the signed-in user already
  /// made, in previous sessions included - _reactedEmoji used to start
  /// empty on every rebuild, so a reaction only looked "active" until the
  /// app restarted even though the UserEngagementEvents doc (the actual
  /// dedup record) was still there the whole time.
  ///
  /// A single whereIn on the 5 deterministic doc IDs rather than 5
  /// separate reads/queries - cheap because the ID itself already encodes
  /// user+post+type, so no filtering by those fields is needed, just an
  /// existence check.
  Future<void> _restoreReactedState() async {
    final userRef = currentUserReference;
    if (userRef == null) return;
    final ids = kQuickReactions
        .map((reaction) =>
            '${userRef.id}_${widget.postRecord.reference.id}_${reaction.eventType}')
        .toList();
    try {
      final snapshot = await UserEngagementEventsRecord.collection
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      if (!mounted) return;
      setState(() {
        for (final doc in snapshot.docs) {
          final eventType = doc.data() is Map
              ? (doc.data() as Map)['event_type'] as String?
              : null;
          if (eventType != null) _reactedEmoji.add(eventType);
        }
      });
    } catch (_) {
      // Leave state as-is - same fail-open behavior as _handleReaction's
      // own try/catch. A missed restore just means those icons render
      // un-highlighted until the next reaction attempt, not a crash.
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExchangeFeedItemModel());
    unawaited(_restoreReactedState());
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
                    if (widget.postRecord.userRef == currentUserReference) ...[
                      // Only on a post tagged to the author's own business -
                      // a customer's untagged post has nothing to promote.
                      if (widget.postRecord.businessRef != null)
                        Tooltip(
                          message: 'Promote in Story Rail',
                          child: InkWell(
                            onTap: () => showModalBottomSheet(
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (context) => Padding(
                                padding: MediaQuery.viewInsetsOf(context),
                                child: CreatePromotionSheet(
                                  businessRef: widget.postRecord.businessRef!,
                                  initialTitle: widget.postRecord.postText,
                                  initialBody: widget.postRecord.postText,
                                  initialImageUrl: widget.postRecord.postImage,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.campaign_outlined,
                                  color: theme.secondaryText, size: 18.0),
                            ),
                          ),
                        ),
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
              if (exchangePostTypeForKey(widget.postRecord.postType) !=
                      null &&
                  widget.postRecord.businessRef != null)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      theme.designToken.spacing.lg,
                      0.0,
                      theme.designToken.spacing.lg,
                      theme.designToken.spacing.sm),
                  child: _PostTypeCtaRow(
                    postType:
                        exchangePostTypeForKey(widget.postRecord.postType)!,
                    businessRef: widget.postRecord.businessRef!,
                  ),
                ),
              if (widget.postRecord.hasNotableReaction() &&
                  _kAmplifyingEventTypes
                      .contains(widget.postRecord.notableReactionEventType))
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      theme.designToken.spacing.lg,
                      0.0,
                      theme.designToken.spacing.lg,
                      theme.designToken.spacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 14.0, color: Color(0xFFFFD700)),
                      SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          '${_amplifyingLabel(widget.postRecord.notableReactionEventType)} '
                          'by ${widget.postRecord.notableReactionName}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600),
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ],
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
                    final count =
                        widget.postRecord.reactionCount(reaction.eventType);
                    return InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _handleReaction(reaction.eventType),
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
                                  // Persisted tally alongside the label once
                                  // someone has reacted - reaction_counts
                                  // only exists once exchange_reaction_counts.js
                                  // has processed at least one event for this
                                  // post/type, so a fresh post with no reads
                                  // yet just shows the plain label as before.
                                  count > 0
                                      ? '${reaction.label} · $count'
                                      : reaction.label,
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
    final scoreRef = KindexScoresRecord.collection.doc(userRef.id);
    return StreamBuilder<DocumentSnapshot>(
      stream: scoreRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox.shrink();
        }
        final scoreRecord = KindexScoresRecord.fromSnapshot(snapshot.data!);
        return KindexTierBadge(
          score: scoreRecord.score,
          isTrendingUp: scoreRecord.isTrendingUp,
          dense: true,
        );
      },
    );
  }
}

/// The category label + explicit CTA button rendered on a post whose
/// author picked a tag in the "New Post" composer (see
/// exchange_post_types.dart). ctaType decides what tapping the button
/// does - 'view_business' is free (the ref is already in hand);
/// 'get_directions' needs one extra read of the business doc for its
/// address/coordinates, done lazily only when tapped rather than for
/// every tagged post the feed renders.
class _PostTypeCtaRow extends StatelessWidget {
  const _PostTypeCtaRow({required this.postType, required this.businessRef});

  final ExchangePostType postType;
  final DocumentReference businessRef;

  Future<void> _handleTap(BuildContext context) async {
    if (postType.ctaType == 'view_business') {
      context.pushNamed(
        BusinessProfileV2Widget.routeName,
        queryParameters: {
          'businessDocument': serializeParam(
            businessRef,
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      );
      return;
    }
    if (postType.ctaType == 'get_directions') {
      final business = await BusinessesRecord.getDocumentOnce(businessRef);
      await launchMap(
        location: business.businessLocation,
        address: business.address,
        title: business.businessName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Icon(postType.icon, size: 14.0, color: theme.accentOnSurface),
        SizedBox(width: 4.0),
        Expanded(
          child: Text(
            postType.label,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              color: theme.accentOnSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
            ),
          ),
        ),
        InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => _handleTap(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                postType.ctaLabel,
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.0,
                ),
              ),
              SizedBox(width: 2.0),
              Icon(Icons.arrow_forward_rounded, size: 14.0, color: theme.primary),
            ],
          ),
        ),
      ],
    );
  }
}
