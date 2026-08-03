import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_preview_card_widget.dart';
import '/components/main_menu_button.dart';
import '/components/notification_bell_button.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/business_category_filter.dart';
import '/services/kin_services.dart';
import '/services/premium_placement.dart';
import '/services/seasonal_theme.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'google_map_page_model.dart';
export 'google_map_page_model.dart';

/// Create a clean, modern, premium dark-themed Discover / Google Map page
/// called "GoogleMapPage" for The Kin App (Black-owned business directory
/// app).
///
/// Theme: Dark luxurious black background with gold and green accents.
///
/// Layout:
/// - Top: Search TextField with placeholder "Search businesses..."
/// - Below search: Horizontal row of filter chips (Near Me, Restaurants,
/// Beauty, Professional, etc.)
/// - Main area: Full Google Map with business markers (use custom
/// KinBusinessMapPinIcon for Black-owned businesses)
/// - Bottom sheet or floating area: ListView of business cards (prioritized
/// for Black-owned)
/// - Top-right corner: Menu IconButton (three dots or hamburger) that opens a
/// Bottom Sheet with navigation options:
///   - The Exchange
///   - My Business / Profile
///   - (Community Feed removed for v1 - see the menu builder below)
///   - Power Hour Blast
///
/// Bottom Navigation Bar with 4 items:
///   - Discover (this page, active)
///   - The Exchange
///   - My Business
///   - Profile
///
/// Backend Query for the business list:
/// - Collection: businesses
/// - No filter, no order, no limit - the whole collection, fetched once
///   per visit (see `GoogleMapPageModel.businesses`).
///
/// This block used to describe an `is_black_owned == true` filter and an
/// `is_priority_pinned desc, kindex_score desc` ordering. Neither was ever
/// implemented, and the filter should not be: `is_black_owned` is set as a
/// per-file blanket constant by the import scripts rather than per
/// business, and is currently true on 17 of 500 documents. Switching it on
/// would empty the map rather than prioritise it. Ordering is applied
/// client-side after the fetch (category chips for the pins,
/// `premiumCarouselBusinesses` for the carousel).
///
/// Make all navigation buttons and menu items fully functional with proper
/// Navigate To actions.
/// Ensure the page works for both customers and business owners.
class GoogleMapPageWidget extends StatefulWidget {
  const GoogleMapPageWidget({super.key});

  static String routeName = 'GoogleMapPage';
  static String routePath = '/googleMapPage';

  @override
  State<GoogleMapPageWidget> createState() => _GoogleMapPageWidgetState();
}

class _GoogleMapPageWidgetState extends State<GoogleMapPageWidget> {
  late GoogleMapPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<BusinessesRecord> _searchResults = [];
  bool _searching = false;

  /// Filters the whole directory (not just what's on screen) by name, so
  /// this doubles as the way to reach a business that has no map pin at
  /// all - e.g. a submission still missing coordinates - rather than only
  /// helping with businesses already visible.
  Future<void> _onSearchChanged(String value) async {
    final query = value.trim();
    safeSetState(() => _searchQuery = query);
    if (query.isEmpty) {
      safeSetState(() => _searchResults = []);
      return;
    }
    safeSetState(() => _searching = true);
    final all = await _model.allBusinessesForSearch();
    if (!mounted) return;
    final lower = query.toLowerCase();
    final matches = all
        .where((b) => b.businessName.toLowerCase().contains(lower))
        .take(8)
        .toList();
    safeSetState(() {
      _searchResults = matches;
      _searching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    safeSetState(() {
      _searchQuery = '';
      _searchResults = [];
    });
  }

  void _selectSearchResult(BusinessesRecord business) {
    _clearSearch();
    _openBusiness(business);
  }

  /// The active category chip. Single-select: tapping a chip makes it the
  /// only active one, and tapping the active chip falls back to Near Me
  /// (no filter).
  BusinessCategoryFilter _selectedCategory = kNearMeFilter;

  /// Independent of the category chip - composes with it rather than
  /// replacing it, so "Food Trucks" + this together finds Black-owned
  /// food trucks specifically. Trusts is_certified_black_owned only (set
  /// exclusively by apply_bob_certification.js), never the unreliable
  /// bulk-imported is_black_owned flag - see BusinessesRecord's doc
  /// comment on the two fields.
  bool _blackOwnedOnly = false;

  /// The map's current visible region, used to bound the businesses query
  /// to what's actually on screen (see GoogleMapPageModel.businessesForViewport).
  /// Null until the map's first onCameraIdle fires, which happens once
  /// automatically right after the map finishes its initial layout.
  LatLngBounds? _viewportBounds;

  void _onCategoryTapped(BusinessCategoryFilter filter) {
    safeSetState(() {
      _selectedCategory =
          identical(_selectedCategory, filter) ? kNearMeFilter : filter;
    });
  }

  Future<void> _onCameraIdle(LatLng latLng) async {
    _model.mapGoogleMapsCenter = latLng;
    try {
      final controller = await _model.mapGoogleMapsController.future
          .timeout(const Duration(seconds: 5));
      final bounds = await controller.getVisibleRegion()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      safeSetState(() => _viewportBounds = bounds);
    } catch (_) {
      // Leave _viewportBounds as-is (possibly null) - build() falls back to
      // an approximate box around the last known center rather than
      // blocking the page on this.
    }
  }

  /// A ~1 degree (roughly 100km) box around [center], used until the real
  /// on-screen bounds are available from the map controller.
  LatLngBounds _fallbackBounds(LatLng center) {
    const delta = 0.5;
    return LatLngBounds(
      southwest: LatLng(center.latitude - delta, center.longitude - delta)
          .toGoogleMaps(),
      northeast: LatLng(center.latitude + delta, center.longitude + delta)
          .toGoogleMaps(),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GoogleMapPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await ActivityLogsRecord.collection
          .doc()
          .set(createActivityLogsRecordData(
            eventType: 'page_view',
            userRef: currentUserReference,
            // No city. This was hardcoded to 'San Antonio', which stamped
            // every map page view in the directory's 76 cities as a San
            // Antonio one. Unlike the profile page's map_tap - which can log
            // the business's own city - a page view has no business in
            // context, and the app still has no user-location plumbing, so
            // there is no honest value. An absent field is a gap in the
            // analytics; a fabricated one is a wrong answer.
            pageName: 'GoogleMapPage',
            sessionId: FFAppState().sessionId,
            timestamp: getCurrentTimestamp,
          ));
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();

    super.dispose();
  }

  void _openBusiness(BusinessesRecord business) {
    // Straight to the full profile. This used to open BusinessShowcase, a
    // thinner page that duplicated this one and rendered only fields that are
    // empty on every business (hero image, established year, interaction
    // count, photo gallery) while omitting the address, phone and website
    // that are actually populated.
    context.pushNamed(
      BusinessProfileV2Widget.routeName,
      queryParameters: {
        'businessDocument': serializeParam(
          business.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  /// Businesses that share a building - a barbecue joint and a tech firm at one
  /// address, a salon and a studio in adjacent suites - geocode to identical
  /// coordinates, and Google Maps then draws one pin exactly on top of the
  /// other. The pin underneath never receives the tap, and with no search on
  /// this page there is no other route to its profile: the business is simply
  /// unreachable in the app.
  ///
  /// So co-located businesses share one pin and the tap opens a picker instead
  /// of guessing which the user meant. Nudging the pins apart was the
  /// alternative and was rejected: at the default zoom, separating two ~40pt
  /// targets means moving a business a few hundred metres, onto the wrong
  /// block.
  List<FlutterFlowMarker> _buildMarkers(List<BusinessesRecord> businesses) {
    final clusters = <String, List<BusinessesRecord>>{};
    for (final business in businesses) {
      final location = business.businessLocation;
      // Some businesses (e.g. bulk-imported rows with corrupted source
      // coordinates) have no business_location - skip them rather than
      // crashing the whole map on a null pin location.
      if (location == null) continue;
      // 5dp is roughly a metre: any closer and no zoom level tells the two
      // pins apart anyway.
      final key = '${location.latitude.toStringAsFixed(5)},'
          '${location.longitude.toStringAsFixed(5)}';
      clusters.putIfAbsent(key, () => []).add(business);
    }

    return clusters.entries.map((entry) {
      final group = entry.value;
      return FlutterFlowMarker(
        // Keyed on the shared coordinate so the id stays stable across
        // rebuilds regardless of which business sorts first.
        entry.key,
        group.first.businessLocation!,
        () async {
          if (group.length == 1) {
            _openBusiness(group.first);
          } else {
            _showCoLocatedPicker(group);
          }
        },
      );
    }).toList();
  }

  /// Zoom in / zoom out, bottom-right.
  ///
  /// Drawn here rather than switching on `showZoomControls`, because that
  /// maps to google_maps_flutter's `zoomControlsEnabled`, which is
  /// Android-only - the iOS Google Maps SDK has no built-in zoom buttons,
  /// so on this app's primary platform the flag does nothing at all. The
  /// corner previously held Google's recentre button, enabled by default
  /// with the location layer switched off behind it, so the one control in
  /// reach did nothing when tapped.
  ///
  /// Zoom gestures still work and are unaffected; these are for the
  /// one-handed case where a pinch isn't practical.
  Widget _zoomControls(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    Future<void> zoomBy(double delta) async {
      // The controller completes in GoogleMap.onMapCreated, which can land
      // after the first frame - awaiting the future rather than reading it
      // means an early tap queues instead of throwing.
      final controller = await _model.mapGoogleMapsController.future;
      await controller.animateCamera(CameraUpdate.zoomBy(delta));
    }

    Widget button(IconData icon, String semantic, double delta,
            {required bool isTop}) =>
        Semantics(
          button: true,
          label: semantic,
          child: InkWell(
            onTap: () => zoomBy(delta),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isTop ? 8.0 : 0.0),
              bottom: Radius.circular(isTop ? 0.0 : 8.0),
            ),
            child: Container(
              width: 44.0,
              height: 44.0,
              alignment: Alignment.center,
              child: Icon(icon, color: theme.primaryText, size: 24.0),
            ),
          ),
        );

    return Align(
      alignment: AlignmentDirectional(1.0, 0.35),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
        child: Container(
          decoration: BoxDecoration(
            // The same near-opaque white the menu button uses, so the two
            // controls read as one set against a light map that the app's
            // dark theme doesn't reach.
            color: Color(0xE6FFFFFF),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(Icons.add_rounded, 'Zoom in', 1.0, isTop: true),
              Container(height: 1.0, width: 28.0, color: theme.alternate),
              button(Icons.remove_rounded, 'Zoom out', -1.0, isTop: false),
            ],
          ),
        ),
      ),
    );
  }

  /// Disambiguates a pin that stands for more than one business.
  void _showCoLocatedPicker(List<BusinessesRecord> businesses) {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(theme.designToken.radius.lg),
              topRight: Radius.circular(theme.designToken.radius.lg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.0,
                  height: 4.0,
                  margin: EdgeInsets.symmetric(
                      vertical: theme.designToken.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 4.0),
                  child: Align(
                    alignment: AlignmentDirectional(-1.0, 0.0),
                    child: Text(
                      '${businesses.length} businesses here',
                      style: theme.titleMedium,
                    ),
                  ),
                ),
                if (businesses.first.address.isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 8.0),
                    child: Align(
                      alignment: AlignmentDirectional(-1.0, 0.0),
                      child: Text(
                        businesses.first.address,
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: businesses.length,
                    itemBuilder: (listContext, index) {
                      final business = businesses[index];
                      return ListTile(
                        leading: Icon(Icons.storefront_rounded,
                            color: theme.primaryText),
                        title:
                            Text(business.businessName, style: theme.bodyLarge),
                        subtitle: business.category.isNotEmpty
                            ? Text(business.category, style: theme.bodySmall)
                            : null,
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: theme.secondaryText),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openBusiness(business);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: theme.designToken.spacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Independent toggle, same visual language as [_categoryChip] - trusts
  /// only is_certified_black_owned (see _blackOwnedOnly's doc comment).
  Widget _blackOwnedChip(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = _blackOwnedOnly;
    final foreground = isSelected ? theme.primaryBackground : theme.primaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => safeSetState(() => _blackOwnedOnly = !_blackOwnedOnly),
      child: Container(
        height: 34.0,
        decoration: BoxDecoration(
          color: isSelected ? theme.tertiary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? theme.tertiary : theme.alternate,
            width: 1.0,
          ),
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: foreground, size: 18.0),
              Text(
                'Black-Owned',
                style: theme.labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: theme.labelMedium.fontWeight,
                    fontStyle: theme.labelMedium.fontStyle,
                  ),
                  color: foreground,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: theme.labelMedium.fontWeight,
                  fontStyle: theme.labelMedium.fontStyle,
                  lineHeight: 1.4,
                ),
              ),
            ].divide(SizedBox(width: 6.0)),
          ),
        ),
      ),
    );
  }

  /// Search box for finding a business by name across the whole directory,
  /// not just the current map viewport - see [GoogleMapPageModel.allBusinessesForSearch].
  Widget _searchField(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 44.0,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: theme.bodyMedium.override(
          font: GoogleFonts.plusJakartaSans(),
          color: theme.primaryText,
          letterSpacing: 0.0,
        ),
        decoration: InputDecoration(
          hintText: 'Search businesses by name',
          hintStyle: theme.bodyMedium.override(
            font: GoogleFonts.plusJakartaSans(),
            color: theme.secondaryText,
            letterSpacing: 0.0,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: theme.secondaryText, size: 20.0),
          suffixIcon: _searchQuery.isNotEmpty
              ? InkWell(
                  onTap: _clearSearch,
                  child: Icon(Icons.close_rounded,
                      color: theme.secondaryText, size: 20.0),
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0.0),
        ),
      ),
    );
  }

  /// Dropdown of name matches shown under the search field while
  /// [_searchQuery] is non-empty. A business without a map pin (no
  /// `business_location`) is flagged rather than hidden - the whole point of
  /// searching the full directory is reaching businesses the map itself
  /// can't show yet.
  Widget _searchResultsList(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      constraints: const BoxConstraints(maxHeight: 320.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.alternate, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _searching
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.secondaryText),
                  ),
                ),
              ),
            )
          : _searchResults.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No businesses match "$_searchQuery".',
                    style: theme.bodySmall
                        .override(color: theme.secondaryText),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  itemBuilder: (listContext, index) {
                    final business = _searchResults[index];
                    final hasPin = business.businessLocation != null;
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.storefront_rounded,
                          color: theme.primaryText, size: 20.0),
                      title: Text(business.businessName,
                          style: theme.bodyMedium
                              .override(color: theme.primaryText)),
                      subtitle: Text(
                        hasPin
                            ? business.category
                            : 'Not on the map yet - view profile',
                        style: theme.labelSmall.override(
                          color:
                              hasPin ? theme.secondaryText : theme.warning,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: theme.secondaryText),
                      onTap: () => _selectSearchResult(business),
                    );
                  },
                ),
    );
  }

  /// One category filter chip. The chips used to be a hand-unrolled set of
  /// five Containers with no tap handler at all, rebuilt once per business
  /// document by a `List.generate(businessList.length, ...)` over a second
  /// full-collection stream - so the row rendered five chips per business
  /// and none of them filtered anything. They are now a single row driven
  /// by [kBusinessCategoryFilters].
  Widget _categoryChip(BuildContext context, BusinessCategoryFilter filter) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = identical(_selectedCategory, filter);
    final foreground = isSelected ? theme.primaryBackground : theme.primaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onCategoryTapped(filter),
      child: Container(
        height: 34.0,
        decoration: BoxDecoration(
          color: isSelected ? theme.tertiary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? theme.tertiary : theme.alternate,
            width: 1.0,
          ),
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                // Near Me keeps its check mark only while it is the active
                // (i.e. unfiltered) chip; otherwise it shows a location
                // glyph so the check never reads as "also selected".
                isSelected || !filter.isMatchAll
                    ? filter.icon
                    : Icons.near_me_rounded,
                color: foreground,
                size: filter.isMatchAll && isSelected ? 16.0 : 18.0,
              ),
              Text(
                filter.label,
                style: theme.labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: theme.labelMedium.fontWeight,
                    fontStyle: theme.labelMedium.fontStyle,
                  ),
                  color: foreground,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: theme.labelMedium.fontWeight,
                  fontStyle: theme.labelMedium.fontStyle,
                  lineHeight: 1.4,
                ),
              ),
            ].divide(SizedBox(width: 6.0)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // Real bounds come from the map's onCameraIdle (see _onCameraIdle),
    // which needs the map to have actually laid out and fired at least
    // once - not guaranteed to have happened by first build, and on some
    // devices/simulators can be slow or need a nudge from user interaction.
    // Gating the whole page on that would mean a stuck spinner forever if
    // it's late; falling back to an approximate box around the initial/last
    // known center means the map and pins still render immediately, and
    // get replaced by the precise viewport the moment the real callback
    // does fire.
    final bounds = _viewportBounds ?? _fallbackBounds(
      _model.mapGoogleMapsCenter ?? LatLng(29.4241, -98.4936),
    );

    return FutureBuilder<List<List<BusinessesRecord>>>(
      future: Future.wait([
        _model.businessesForViewport(bounds),
        _model.premiumBusinesses(),
      ]),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ),
            ),
          );
        }
        List<BusinessesRecord> googleMapPageBusinessesRecordList =
            snapshot.data![0];

        // Map pins honour both the active category chip and the
        // Black-Owned toggle - independent filters, composed in sequence.
        final visibleBusinesses = applyCategoryFilter(
          _blackOwnedOnly
              ? googleMapPageBusinessesRecordList
                  .where((b) => b.isCertifiedBlackOwned)
                  .toList()
              : googleMapPageBusinessesRecordList,
          _selectedCategory,
        );

        // The carousel deliberately does NOT honour the category chip or
        // the map viewport: these are paid placements, and narrowing them
        // by whatever the user is browsing or has panned to would silently
        // take away exposure a merchant bought. Eligibility is
        // subscription status only - see GoogleMapPageModel.premiumBusinesses.
        final premiumBusinesses =
            premiumCarouselBusinesses(snapshot.data![1]);

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            resizeToAvoidBottomInset: false,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Stack(
              alignment: AlignmentDirectional(-1.0, -1.0),
              children: [
                Container(
                  child: FlutterFlowGoogleMap(
                    controller: _model.mapGoogleMapsController,
                    onCameraIdle: _onCameraIdle,
                    initialLocation: _model.mapGoogleMapsCenter ??=
                        LatLng(29.4241, -98.4936),
                    markers: _buildMarkers(visibleBusinesses),
                    // Amber, to match the app's gold/amber identity - violet
                    // belonged to no palette in the app. Google only exposes
                    // ten preset marker hues, and orange (hue 30) is the one
                    // that lands on the amber token used elsewhere
                    // (0xFFFF8C00). Pure yellow sits closer to the gold
                    // 0xFFFFD700 but washes out badly against the light map
                    // background.
                    //
                    // Per-business logos are not reachable from here:
                    // FlutterFlowGoogleMap takes a single markerImage for
                    // every pin, not one per marker.
                    markerColor: GoogleMarkerColor.orange,
                    mapType: MapType.normal,
                    style: currentSeasonalTheme().mapStyle,
                    initialZoom: 14.0,
                    allowInteraction: true,
                    allowZoom: true,
                    // Stays false: it's Android-only, and this app's zoom
                    // buttons are drawn by _zoomControls so both platforms
                    // get the same control in the same place.
                    showZoomControls: false,
                    showLocation: false,
                    // Was drawing Google's recentre button bottom-right by
                    // default, with the location layer switched off behind
                    // it - a button that did nothing, occupying exactly the
                    // corner people reach for to zoom.
                    showLocationButton: false,
                    showCompass: false,
                    showMapToolbar: false,
                    showTraffic: false,
                    centerMapOnMarkerTap: true,
                    // The map is the full-bleed background of a Stack, so
                    // it has to win pan/pinch/rotate outright. With this
                    // false, FlutterFlowGoogleMap registers no gesture
                    // recognizers on the platform view, and the page's
                    // surrounding GestureDetector/Stack keeps the map from
                    // ever receiving a drag - the map renders but cannot be
                    // moved. True installs an EagerGestureRecognizer, which
                    // is what makes scroll, zoom and rotate work.
                    mapTakesGesturePreference: true,
                  ),
                ),
                _zoomControls(context),
                Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primaryBackground,
                          Color(0x00FCFCFC)
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(0.0, -1.0),
                        end: AlignmentDirectional(0, 1.0),
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    // The page has no Scaffold AppBar and the map is
                    // full-bleed, so without this the 24px top padding put
                    // the menu button underneath the status bar / notch,
                    // where iOS eats the touches before Flutter sees them -
                    // the button looked dead even though its handler was
                    // wired. SafeArea drops it below the inset.
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 16.0, 24.0),
                        child: Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const MainMenuButton(),
                                  const NotificationBellButton(),
                                ].divide(SizedBox(width: 8.0)),
                              ),
                              _searchField(context),
                              if (_searchQuery.isNotEmpty)
                                _searchResultsList(context),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ...kBusinessCategoryFilters.map(
                                        (filter) =>
                                            _categoryChip(context, filter)),
                                    _blackOwnedChip(context),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The bronze "sparkle" pin that used to sit here (a
                // hardcoded Align at (0.1, -0.2) drawing location_on_rounded
                // + auto_awesome_rounded in theme.tertiary) was a leftover
                // decorative marker, not a business: it was pinned to a
                // fraction of the screen rather than a LatLng, so it never
                // moved with the map and had no Firestore document behind
                // it. Removed. Real pins all come from the `markers:`
                // argument on the map above.
                //
                // Premium placement carousel: dynamic scrolling marketplace
                // showing all paid-tier businesses with animation effects.
                // Multiple businesses visible simultaneously (3-4 cards).
                // Auto-scrolls continuously with smooth animations.
                // Tier-gated visibility: Free=none, Founding Local=regular,
                // Founding Local+=premium, Elite/Yearly=featured.
                // Location Beacon active trucks get "We're Here" treatment
                // with pulsing animation to draw attention.
                if (premiumBusinesses.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 100.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'See All',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Animated carousel: horizontal scroll with multiple
                          // businesses visible + animation effects for active beacons
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(
                                  premiumBusinesses.length,
                                  (index) {
                                    final business = premiumBusinesses[index];
                                    final isBeaconActive =
                                        business.mobileLocationActive ?? false;
                                    final isMobileVendor =
                                        business.isMobileVendor ?? false;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => context.pushNamed(
                                        BusinessProfileV2Widget.routeName,
                                        queryParameters: {
                                          'businessDocument': serializeParam(
                                            business.reference,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                      ),
                                      // Beacon-active cards get special styling
                                      // with green border and glow effect
                                      child: isBeaconActive && isMobileVendor
                                          ? Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Color(0xFF4FBF85),
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xFF4FBF85)
                                                        .withOpacity(0.6),
                                                    blurRadius: 12.0,
                                                    spreadRadius: 2.0,
                                                  ),
                                                ],
                                              ),
                                              child: wrapWithModel(
                                                model: _model
                                                    .premiumCardModels[index],
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child:
                                                    BusinessPreviewCardWidget(
                                                  name: business.businessName,
                                                  isPriority: business
                                                      .isPriorityPinned,
                                                  category: business.category,
                                                  rating: formatNumber(
                                                    business.reviewScore,
                                                    formatType:
                                                        FormatType.decimal,
                                                    decimalType:
                                                        DecimalType
                                                            .periodDecimal,
                                                  ),
                                                  imageUrl:
                                                      business.heroImage,
                                                ),
                                              ),
                                            )
                                          : wrapWithModel(
                                              model: _model
                                                  .premiumCardModels[index],
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child:
                                                  BusinessPreviewCardWidget(
                                                name: business.businessName,
                                                isPriority:
                                                    business.isPriorityPinned,
                                                category: business.category,
                                                rating: formatNumber(
                                                  business.reviewScore,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType: DecimalType
                                                      .periodDecimal,
                                                ),
                                                imageUrl: business.heroImage,
                                              ),
                                            ),
                                    );
                                  },
                                ).divide(SizedBox(width: 16.0)),
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar:
                KinBottomNav2Widget(currentPage: KinNavPage.directory),
          ),
        );
      },
    );
  }
}
