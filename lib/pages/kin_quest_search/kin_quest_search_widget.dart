import '/backend/backend.dart';
import '/components/add_traveler_discovery_dialog.dart';
import '/components/main_menu_button.dart';
import '/components/report_business_sheet.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/kin_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kin_quest_search_model.dart';
export 'kin_quest_search_model.dart';

/// "Traveling?" entry point off the KIN Quest list - searches the whole
/// directory by name/city rather than filtering to kNearbyFeedRadiusKm, so a
/// user who has traveled well outside their home radius can still find and
/// check into a business they encountered or heard about, or add it if it
/// isn't in KIN yet.
///
/// Deliberately its own page rather than a mode toggle on KinQuestWidget:
/// the two lists answer different questions ("what's near me" vs. "is this
/// specific business in KIN"), and keeping them separate means the default
/// Quest experience for the vast majority of non-traveling users is
/// unchanged.
class KinQuestSearchWidget extends StatefulWidget {
  const KinQuestSearchWidget({super.key});

  static String routeName = 'KinQuestSearch';
  static String routePath = '/kinQuestSearch';

  @override
  State<KinQuestSearchWidget> createState() => _KinQuestSearchWidgetState();
}

class _KinQuestSearchWidgetState extends State<KinQuestSearchWidget> {
  late KinQuestSearchModel _model;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KinQuestSearchModel());
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isRare(BusinessesRecord b) =>
      b.rarityTier == 'Rare' || b.rarityTier == 'Hidden Gem';

  List<BusinessesRecord> _matches(List<BusinessesRecord> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return all.where((b) {
      return b.businessName.toLowerCase().contains(q) ||
          b.city.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _checkIn(BusinessesRecord business) async {
    if (_model.checkingIn) return;
    safeSetState(() => _model.checkingIn = true);
    final result = await KinServices.checkInToBusiness(
      businessRef: business.reference,
    );
    if (!mounted) return;
    safeSetState(() => _model.checkingIn = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    final checkIn = result.data!;
    final message = checkIn.alreadyCheckedIn
        ? "You've already checked in here recently."
        : checkIn.rarityTier == 'Standard'
            ? 'Checked in! +${checkIn.pointsAwarded} points.'
            : "${checkIn.rarityTier} find! +${checkIn.pointsAwarded} points.";

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddDiscovery() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTravelerDiscoveryDialog(
        initialName: _searchController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'Find a Business Anywhere',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
        actions: [Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: MainMenuButton(),
        )],
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Traveling or heard about a spot out of town? Search the '
                'whole KIN directory here, not just what\'s nearby.',
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => safeSetState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Business name, city, or category',
                  hintStyle: theme.bodySmall.override(color: theme.hint),
                  prefixIcon: Icon(Icons.search_rounded, color: theme.secondaryText),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(14.0),
                ),
                style: theme.bodyMedium.override(color: theme.primaryText),
              ),
              SizedBox(height: 16.0),
              Expanded(
                child: FutureBuilder<List<BusinessesRecord>>(
                  future: _model.businesses(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      );
                    }
                    if (_query.trim().isEmpty) {
                      return _hint(theme, 'Start typing to search anywhere in KIN.');
                    }

                    final matches = _matches(snapshot.data!);
                    if (matches.isEmpty) {
                      return _notFound(theme);
                    }

                    return ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.0),
                      itemBuilder: (context, i) =>
                          _resultRow(theme, matches[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint(FlutterFlowTheme theme, String text) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.bodyMedium.override(color: theme.secondaryText),
          ),
        ),
      );

  Widget _notFound(FlutterFlowTheme theme) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't find that in KIN yet",
                textAlign: TextAlign.center,
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.0),
              Text(
                'If you\'ve found a Black-owned business here that isn\'t '
                'listed, add it and we\'ll review it.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(color: theme.secondaryText),
              ),
              SizedBox(height: 16.0),
              InkWell(
                onTap: _openAddDiscovery,
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    'Add This Business',
                    style: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _resultRow(FlutterFlowTheme theme, BusinessesRecord business) {
    final isRare = _isRare(business);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: isRare ? Border.all(color: theme.primary.withAlpha(140)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.businessName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (business.city.isNotEmpty) business.city,
                    business.category,
                    if (isRare) business.rarityTier,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: theme.labelSmall.override(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _model.checkingIn ? null : () => _checkIn(business),
            borderRadius: BorderRadius.circular(999.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: theme.alternate),
                borderRadius: BorderRadius.circular(999.0),
              ),
              child: Text(
                'Check In',
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Same report/remove action as the Quest list. This screen needs it
          // more, not less: searching by name is how you reach a specific
          // listing you already know doesn't belong, without having to be
          // standing next to it.
          IconButton(
            onPressed: () => showReportBusinessSheet(
              context,
              business: business,
              onHidden: () => safeSetState(() => _model.refreshBusinesses()),
            ),
            icon: Icon(Icons.more_vert_rounded,
                size: 18.0, color: theme.secondaryText),
            visualDensity: VisualDensity.compact,
            tooltip: 'Report this listing',
          ),
        ],
      ),
    );
  }
}
