import '/components/rank_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/business_profile_v2/business_profile_v2_widget.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kindex_spotlight_model.dart';
export 'kindex_spotlight_model.dart';

// 'Kindex Spotlight' preview card for The Exchange. Business Owners are
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
                    'Kindex Spotlight',
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
    final topBusiness =
        _businessEntries.isNotEmpty ? _businessEntries.first : null;
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
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            border: Border.all(color: Color(0xFF333333), width: 1.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.designToken.spacing.md),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700), size: 22.0),
                SizedBox(width: theme.designToken.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kindex Spotlight',
                        style: theme.bodyMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.0,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        _loading
                            ? 'Loading leaderboard...'
                            : [
                                if (topBusiness != null)
                                  '🏆 ${topBusiness.name} · ${topBusiness.score.toStringAsFixed(0)}',
                                if (topCustomer != null)
                                  '⭐ ${topCustomer.name} · ${topCustomer.score.toStringAsFixed(0)}',
                              ].join('   '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: Color(0xFFAAAAAA),
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFAAAAAA), size: 20.0),
              ],
            ),
          ),
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
