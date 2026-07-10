import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exchange_feed_item_model.dart';
export 'exchange_feed_item_model.dart';

// Quick Reaction emoji -> the Kindex event_type it logs. These event types
// are already live in kindex_config/scoring_weights.
const _kQuickReactions = <String, String>{
  '❤️': 'react_love',
  '🙌🏾': 'react_praise',
  '🔥': 'react_fire',
  '✨': 'react_sparkle',
  '👏🏾': 'react_applause',
};

class ExchangeFeedItemWidget extends StatefulWidget {
  const ExchangeFeedItemWidget({
    super.key,
    required this.postRecord,
    required this.businessRef,
    this.authorDisplayName,
    this.authorPhotoUrl,
  });

  final ExchangePostsRecord postRecord;
  final DocumentReference businessRef;
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
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(theme.designToken.radius.full),
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              theme.designToken.radius.full),
                          border: Border.all(color: theme.divider, width: 1.0),
                        ),
                        child: CachedNetworkImage(
                          fadeInDuration: Duration(milliseconds: 0),
                          fadeOutDuration: Duration(milliseconds: 0),
                          imageUrl: valueOrDefault<String>(
                            widget.authorPhotoUrl,
                            'https://dimg.dreamflow.cloud/v1/image/modern%20professional%20black%20woman%20headshot',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: theme.designToken.spacing.sm),
                    Expanded(
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
                            widget.postRecord.timestamp != null
                                ? dateTimeFormat(
                                    'relative', widget.postRecord.timestamp!)
                                : '',
                            style: theme.labelSmall.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: theme.hint,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
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
                  children: _kQuickReactions.entries.map((entry) {
                    final emoji = entry.key;
                    final eventType = entry.value;
                    final isActive = _reactedEmoji.contains(emoji);
                    return InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _handleReaction(emoji, eventType),
                      child: AnimatedScale(
                        scale: isActive ? 1.3 : 1.0,
                        duration: Duration(milliseconds: 150),
                        child: Opacity(
                          opacity: isActive ? 1.0 : 0.6,
                          child: Text(
                            emoji,
                            style: theme.titleMedium.override(
                              font: GoogleFonts.plusJakartaSans(),
                              letterSpacing: 0.0,
                            ),
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
