import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/business_preview_card_widget.dart';
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

    super.dispose();
  }

  /// The hamburger menu's bottom sheet: The Exchange / My Business / The
  /// KIN Quest. The Exchange requires a real businessRef, so it's the only
  /// item gated on actually owning a business - My Business self-guards
  /// internally (OwnerProfileWidget already shows its own "set up your
  /// business" empty state).
  ///
  /// Community Feed used to sit between them, pointing at
  /// CommunityPrestigeWidget - a v2/v3 rewards concept that read nothing
  /// from Firestore and rendered hardcoded businesses/scores. Deleted
  /// outright rather than left for later work, since nothing else pointed
  /// at it once this entry was removed. Power Hour Blast also used to sit
  /// here - removed because this menu is reachable by customers, and
  /// starting a Power Hour is owner-only; see PowerHourPanelWidget on
  /// Owner Profile instead.
  void _showMainMenu(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(theme.designToken.radius.lg),
              topRight: Radius.circular(theme.designToken.radius.lg),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: theme.designToken.spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.0,
                    height: 4.0,
                    margin:
                        EdgeInsets.only(bottom: theme.designToken.spacing.md),
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.forum_outlined, color: theme.primaryText),
                    title: Text('The Exchange', style: theme.bodyLarge),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      // No longer gated on owning a business. The Exchange
                      // is a global feed that anyone can read and post to,
                      // so requiring a business here turned the menu item
                      // into a no-op with a snackbar for every customer -
                      // most of the people it exists for. A null ref just
                      // means posts carry no business tag.
                      final businessRef = currentUserDocument?.ownedBusiness;
                      context.pushNamed(
                        TheExchangeWidget.routeName,
                        queryParameters: {
                          'businessRef': serializeParam(
                            businessRef,
                            ParamType.DocumentReference,
                          ),
                        }.withoutNulls,
                      );
                    },
                  ),
                  // Was unconditionally OwnerProfileWidget - every signed-in
                  // user got the owner dashboard regardless of role. A
                  // customer with no owned business landed on
                  // OwnerProfileWidget's "set up your business" empty state
                  // instead of their own profile. Branches on the same
                  // ownedBusiness check OwnerProfileWidget itself already
                  // guards on (see its build() method).
                  ListTile(
                    leading: Icon(
                      currentUserDocument?.ownedBusiness != null
                          ? Icons.storefront_rounded
                          : Icons.person_rounded,
                      color: theme.primaryText,
                    ),
                    title: Text(
                      currentUserDocument?.ownedBusiness != null
                          ? 'My Business / Profile'
                          : 'My Profile',
                      style: theme.bodyLarge,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.pushNamed(
                        currentUserDocument?.ownedBusiness != null
                            ? OwnerProfileWidget.routeName
                            : CustomerProfilePageWidget.routeName,
                      );
                    },
                  ),
                  // 'Community Feed' used to point at CommunityPrestigeWidget,
                  // a v2/v3 rewards concept that read nothing from Firestore
                  // and rendered hardcoded businesses and scores ('Avenue
                  // Bistro', 'Urban Greens' 912). Shipping a main menu entry
                  // to a mockup made the whole app look like a demo, so both
                  // the entry point and the page itself have been removed.
                  //
                  // 'Power Hour Blast' also removed from here - this menu is
                  // reachable by every signed-in user, customers included,
                  // but starting a Power Hour is an owner-only action. That
                  // control already lives on Owner Profile (PowerHourPanelWidget)
                  // and needs no separate entry point; the full-page flow this
                  // used to open (MobileCalledPowerPageWidget) was a broken,
                  // redundant duplicate and has been retired.
                  // Same slot, different destination by role. A business
                  // owner has no reason to play the customer Quest
                  // themselves (see KinQuestWidget's own doc comment -
                  // deliberately customer-only), but the underlying
                  // check-in data is exactly what they'd want to see about
                  // their own business - so this becomes their insights
                  // dashboard instead of just disappearing.
                  ListTile(
                    leading: Icon(
                      currentUserDocument?.ownedBusiness != null
                          ? Icons.insights_rounded
                          : Icons.explore_rounded,
                      color: theme.primaryText,
                    ),
                    title: Text(
                      currentUserDocument?.ownedBusiness != null
                          ? 'Business Insights'
                          : 'The KIN Quest',
                      style: theme.bodyLarge,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.pushNamed(
                        currentUserDocument?.ownedBusiness != null
                            ? BusinessInsightsWidget.routeName
                            : KinQuestWidget.routeName,
                      );
                    },
                  ),
                  Divider(
                    height: theme.designToken.spacing.md,
                    thickness: 1.0,
                    indent: 16.0,
                    endIndent: 16.0,
                    color: theme.alternate,
                  ),
                  // The account row. Before this existed there was no way to
                  // sign out anywhere in the app, so a device stayed signed in
                  // to whoever used it first.
                  if (loggedIn)
                    ListTile(
                      leading:
                          Icon(Icons.logout_rounded, color: theme.error),
                      title: Text(
                        'Sign Out',
                        style: theme.bodyLarge.override(color: theme.error),
                      ),
                      subtitle: currentUserEmail.isEmpty
                          ? null
                          : Text(
                              currentUserEmail,
                              style: theme.bodySmall
                                  .override(color: theme.secondaryText),
                            ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _confirmSignOut(context);
                      },
                    )
                  else
                    ListTile(
                      leading:
                          Icon(Icons.login_rounded, color: theme.primaryText),
                      title: Text('Sign In', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(SignInPageWidget.routeName);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Confirm-gated, matching how Power Hour's stop button is gated: this sits
  /// one tap away from four navigation items, and an accidental sign-out
  /// strands someone until they remember their password.
  Future<void> _confirmSignOut(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final email = currentUserEmail;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        title: Text('Sign out?', style: theme.titleMedium),
        content: Text(
          email.isEmpty
              ? 'You\'ll need to sign in again to claim a business, check in, or post.'
              : 'You\'ll be signed out of $email, and will need to sign in '
                  'again to claim a business, check in, or post.',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: theme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Sign Out',
              style: theme.bodyMedium.override(color: theme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // The router rebuilds on an auth change unless it's told one is coming,
    // which would interrupt the navigation below. See
    // AppStateNotifier.updateNotifyOnAuthChange.
    GoRouter.of(context).prepareAuthEvent();

    final result = await KinServices.signOut();
    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }
    context.goNamedAuth(SignInPageWidget.routeName, context.mounted);
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
                                  Container(
                                    width: 48.0,
                                    height: 48.0,
                                    decoration: BoxDecoration(
                                      color: Color(0xE6FFFFFF),
                                      borderRadius:
                                          BorderRadius.circular(9999.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: FlutterFlowIconButton(
                                      borderRadius: 8.0,
                                      buttonSize: 40.0,
                                      fillColor: Colors.transparent,
                                      icon: Icon(
                                        Icons.menu_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        size: 24.0,
                                      ),
                                      onPressed: () {
                                        _showMainMenu(context);
                                      },
                                    ),
                                  ),
                                  const NotificationBellButton(),
                                ].divide(SizedBox(width: 8.0)),
                              ),
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
                // Premium placement carousel: paid subscribers only, three
                // at a time, rotated by `premiumCarouselBusinesses` so the
                // exposure is shared across every paid business rather than
                // parked on the same three. Hidden entirely when nobody is
                // on a paid plan - an empty shelf beats inventing filler.
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
                          // No heading above the cards. The shelf carried
                          // 'Black-Owned Near You', then 'Featured Partners'
                          // once it became a paid-placement carousel; both
                          // described the shelf rather than helping anyone
                          // use it, and the card treatment already reads as
                          // a recommended set. 'See All' stays because it
                          // predates this work and is out of scope - it is
                          // now right-aligned on its own, keeping the exact
                          // position it had beside the removed heading.
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
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      // A paid placement that can't be opened
                                      // isn't a placement. The green arrow
                                      // button that used to sit at the end of
                                      // this row was the only tappable thing
                                      // here, and it always opened whichever
                                      // business happened to be first in the
                                      // unfiltered query - unrelated to the
                                      // card next to it. Removed in favour of
                                      // per-card taps.
                                      onTap: () => context.pushNamed(
                                        BusinessProfileV2Widget.routeName,
                                        queryParameters: {
                                          'businessDocument': serializeParam(
                                            business.reference,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                      ),
                                      child: wrapWithModel(
                                        model: _model.premiumCardModels[index],
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: BusinessPreviewCardWidget(
                                          name: business.businessName,
                                          isPriority: business.isPriorityPinned,
                                          category: business.category,
                                          rating: formatNumber(
                                            business.reviewScore,
                                            formatType: FormatType.decimal,
                                            decimalType:
                                                DecimalType.periodDecimal,
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
