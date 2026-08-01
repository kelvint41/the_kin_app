import '/components/rank_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kindex_spotlight_model.dart';
export 'kindex_spotlight_model.dart';

const _gold = Color(0xFFFFD700);
const _silver = Color(0xFFC0C0C0);
const _bronze = Color(0xFFCD7F32);

// 'KINDEX Spotlight' preview card for The Exchange. Business Owners are
// ranked by their business's kindex_score; Customers are ranked by their
// personal KindexScores.score - two separate scoring tracks that already
// power the onboarding ticker (see KinServices.fetchTopBusinessKindex /
// fetchTopCustomerKindex), reused here rather than re-queried from scratch.
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KindexSpotlightModel());
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final businessResult = await KinServices.fetchTopBusinessKindex(limit: 10);
    final customerResult = await KinServices.fetchTopCustomerKindex(limit: 10);
    if (!mounted) return;
    setState(() {
      _businessEntries = businessResult.data ?? [];
      _customerEntries = customerResult.data ?? [];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _openLeaderboard(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(theme.designToken.radius.lg),
                  topRight: Radius.circular(theme.designToken.radius.lg),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(theme.designToken.spacing.lg),
                children: [
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      margin:
                          EdgeInsets.only(bottom: theme.designToken.spacing.md),
                      decoration: BoxDecoration(
                        color: theme.alternate,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  Text(
                    'KINDEX Spotlight',
                    style: theme.headlineSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold),
                      color: theme.primaryText,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                    ),
                  ),
                  SizedBox(height: theme.designToken.spacing.lg),
                  _LeaderboardSection(
                    title: 'Top Business Owners',
                    entries: _businessEntries,
                    descLabel: 'Business',
                  ),
                  SizedBox(height: theme.designToken.spacing.xl),
                  _LeaderboardSection(
                    title: 'Top Customers',
                    entries: _customerEntries,
                    descLabel: 'Community Member',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final topThreeBusinesses = _businessEntries.take(3).toList();
    final topCustomer =
        _customerEntries.isNotEmpty ? _customerEntries.first : null;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(theme.designToken.spacing.lg, 0.0,
          theme.designToken.spacing.lg, theme.designToken.spacing.lg),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: _loading ? null : () => _openLeaderboard(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            border: Border.all(color: Color(0x33FFD700), width: 1.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.designToken.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 20.0)),
                    SizedBox(width: theme.designToken.spacing.sm),
                    Expanded(
                      child: Text(
                        'KINDEX Spotlight',
                        style: theme.bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFAAAAAA), size: 20.0),
                  ],
                ),
                SizedBox(height: theme.designToken.spacing.md),
                if (_loading)
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: theme.designToken.spacing.md),
                    child: Text(
                      'Loading leaderboard...',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.plusJakartaSans(),
                        color: Color(0xFFAAAAAA),
                        letterSpacing: 0.0,
                      ),
                    ),
                  )
                else if (topThreeBusinesses.isEmpty)
                  Text(
                    'No ranked businesses yet.',
                    style: theme.labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(),
                      color: Color(0xFFAAAAAA),
                      letterSpacing: 0.0,
                    ),
                  )
                else
                  _Podium(entries: topThreeBusinesses),
                if (topCustomer != null) ...[
                  SizedBox(height: theme.designToken.spacing.sm),
                  Row(
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 13.0)),
                      SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          'Top community member: ${topCustomer.name} · ${topCustomer.score.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(),
                            color: Color(0xFFAAAAAA),
                            letterSpacing: 0.0,
                          ),
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
          .shimmer(duration: 1200.ms, color: Color(0x33FFD700)),
    );
  }
}

/// Top-3 business mini-podium: rank 1 centered and taller, 2 and 3 flanking
/// it lower - the classic podium shape, in place of the old single trophy
/// line. Medal colours on the rank badge do the identification work instead
/// of a numeral, since gold/silver/bronze reads faster than "1/2/3" here.
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((i) => _PodiumSlot(rank: i, entry: entries[i])).toList(),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.rank, required this.entry});

  /// 0-indexed: 0 = gold, 1 = silver, 2 = bronze.
  final int rank;
  final KindexTickerEntry entry;

  static const _medalColors = [_gold, _silver, _bronze];
  static const _medalEmoji = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final medal = _medalColors[rank];
    final isFirst = rank == 0;
    final avatarSize = isFirst ? 52.0 : 42.0;
    final initial =
        entry.name.trim().isNotEmpty ? entry.name.trim()[0].toUpperCase() : '?';

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
      child: Padding(
        padding: EdgeInsets.only(top: isFirst ? 0.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_medalEmoji[rank], style: TextStyle(fontSize: isFirst ? 20.0 : 16.0)),
            SizedBox(height: 4.0),
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
                border: Border.all(color: medal, width: 2.0),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4.0),
            SizedBox(
              width: 76.0,
              child: Text(
                entry.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Text(
              entry.score.toStringAsFixed(0),
              style: theme.labelSmall.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                color: medal,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({
    required this.title,
    required this.entries,
    required this.descLabel,
  });

  final String title;
  final List<KindexTickerEntry> entries;
  final String descLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.titleSmall.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.0,
          ),
        ),
        SizedBox(height: theme.designToken.spacing.sm),
        if (entries.isEmpty)
          Text(
            'No ranked members yet.',
            style: theme.bodySmall.override(
              font: GoogleFonts.plusJakartaSans(),
              color: theme.secondaryText,
              letterSpacing: 0.0,
            ),
          )
        else
          ...entries.asMap().entries.map((indexed) {
            final rank = indexed.key + 1;
            final entry = indexed.value;
            final businessRef = entry.businessRef;
            final row = RankCardWidget(
              rank: rank.toString(),
              name: entry.name,
              desc: descLabel,
              score: entry.score.toStringAsFixed(0),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: theme.designToken.spacing.sm),
              child: businessRef == null
                  ? row
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(
                            BusinessProfileV2Widget.routeName,
                            queryParameters: {
                              'businessDocument': serializeParam(
                                businessRef,
                                ParamType.DocumentReference,
                              ),
                            }.withoutNulls,
                          );
                        },
                        child: row,
                      ),
                    ),
            );
          }),
      ],
    );
  }
}
