import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/services/subscription_tiers.dart';
import '/components/compact_action_list_widget.dart';
import '/components/kin_back_button.dart';
import '/components/kindex_engagement_nudge.dart';
import '/components/support_bubble_widget.dart';
import '/components/power_hour_panel_widget.dart';
import '/components/location_beacon_card_widget.dart';
import '/components/subscription_management_row.dart';
import '/components/owner_roi_dashboard_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Promote, Power Hour, membership/upgrade prompts, and listing management,
/// pulled out of Owner Profile's main screen into their own page.
///
/// Owner Profile used to put all of this - plus Profile Info and the
/// KINDEX Score an owner actually needs at a glance every visit - on one
/// long scroll. Everything here is either a growth/promotion action
/// (Promote, Power Hour, upgrading tiers) or listing management (My
/// Items/Jobs/Events), not something an owner needs to see every time they
/// open their profile - see the reorganized main screen for what stayed.
class GrowthToolsPageWidget extends StatelessWidget {
  const GrowthToolsPageWidget({super.key});

  static String routeName = 'GrowthToolsPage';
  static String routePath = '/growthToolsPage';

  void _showManageListingsSheet(BuildContext context) {
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
          // Material re-established here - same "background is hidden"
          // ListTile assertion fix as main_menu_button.dart's hamburger
          // sheet and google_map_page_widget.dart's sheets: this
          // Container's opaque decoration otherwise sits between the
          // sheet's own (transparent) Material and every ListTile below.
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: theme.designToken.spacing.md),
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
                      leading: Icon(Icons.storefront_rounded,
                          color: theme.primaryText),
                      title: Text('My Items', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(MyItemsWidget.routeName);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.work_outline_rounded,
                          color: theme.primaryText),
                      title: Text('Manage Jobs', style: theme.bodyLarge),
                      subtitle: Text(
                        'Also where applicant messages live.',
                        style: theme.labelSmall
                            .override(color: theme.secondaryText),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(JobManagementPage.routeName);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.volunteer_activism_outlined,
                          color: theme.primaryText),
                      title: Text('Manage Events', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(EventManagementPage.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Real per-tier feature copy - kept word-for-word identical to
  /// merchant_pricing_suite_widget.dart's own f1-f4 bullets (the actual
  /// purchase flow's tier cards) so this comparison can never drift from
  /// what upgrading actually gets someone. One canonical source of truth,
  /// just displayed in two places.
  static const Map<String, List<String>> _tierFeatures = {
    'Community': [
      'Access to public community forums',
      'Basic business profile page on local directory',
      'Up to 3 active local connections',
      'Basic community support',
    ],
    'Founder': [
      'Weekly carousel rotations',
      'Basic business profile analytics',
      'Post 1 promotion per month on The Exchange',
      'Community support',
    ],
    'Founding Local': [
      'Verified Founding Member trust badge',
      'Up to 5 gallery photos on profile',
      'Basic profile analytics (views & trends)',
      'Post 1 promotion per month on The Exchange',
    ],
    'Premium Local': [
      'Premium interactive map carousel placement',
      'Location Beacon feature (broadcast your location)',
      'Advanced performance analytics & insights',
      'Priority support + featured business badge',
    ],
    'Elite': [
      'Always featured on carousel (daily visibility)',
      'Unlimited Location Beacons for mobile services',
      'Priority support + account manager',
      'Custom branding & co-marketing opportunities',
    ],
  };

  /// Also mirrors merchant_pricing_suite_widget.dart's own _priceFor calls
  /// (the monthly figure - annual pricing/discount stays on the actual
  /// purchase page, this is a comparison summary, not a checkout).
  static const Map<String, String> _tierPrices = {
    'Community': 'Free',
    'Founder': '\$29/mo',
    'Founding Local': '\$59/mo',
    'Premium Local': '\$99/mo',
    'Elite': '\$149/mo',
  };

  /// One feature row - a checkmark when [cardTier] is a tier the business
  /// already has (at or below their actual [currentTier]), a lock when it
  /// isn't. Previously this compared the business's own tier against a
  /// fixed feature's OWN minimum tier, always evaluated against whichever
  /// tier was already current - meaningful for "do I have this feature"
  /// but with only one tier's card ever shown, a Community business saw
  /// nothing but locks and no way to see what stepping up would actually
  /// unlock. This version is called once per tier CARD instead, so every
  /// tier's own full feature list renders, checked against whether that
  /// whole tier is included.
  Widget _tierFeatureRow(BuildContext context, String label, bool included) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(
          included ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          color: included ? theme.accent1 : theme.secondaryText,
          size: 18.0,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
            child: Text(
              label,
              style: theme.bodySmall.override(
                font: GoogleFonts.plusJakartaSans(),
                color: included ? const Color(0xFFD4AF37) : theme.secondaryText,
                letterSpacing: 0.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One tier's full card in the comparison - name, price, "CURRENT PLAN"
  /// badge when it matches [currentTier], and all four of its real
  /// features, checked (not locked) since a business on this tier or
  /// higher already has everything a lower tier offers.
  Widget _tierComparisonCard(
      BuildContext context, String cardTier, String currentTier) {
    final theme = FlutterFlowTheme.of(context);
    final isCurrent = cardTier == currentTier;
    final included = tierAtLeast(currentTier, cardTier);
    final features = _tierFeatures[cardTier] ?? const [];

    return Container(
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                colors: [theme.primary, const Color(0xFF06251B)],
                stops: [0.0, 1.0],
                begin: AlignmentDirectional(1.0, 1.0),
                end: AlignmentDirectional(-1.0, -1.0),
              )
            : null,
        color: isCurrent ? null : theme.secondaryBackground,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isCurrent ? theme.accent1.withAlpha(51) : theme.alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      cardTier,
                      style: theme.titleMedium.override(
                        font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold),
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.accent1.withAlpha(51),
                            borderRadius: BorderRadius.circular(9999.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 3.0, 10.0, 3.0),
                            child: Text(
                              'CURRENT PLAN',
                              style: theme.labelSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold),
                                color: const Color(0xFFD4AF37),
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  _tierPrices[cardTier] ?? '',
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                    color: isCurrent ? theme.primaryText : theme.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final feature in features)
                  _tierFeatureRow(context, feature, included),
              ].divide(SizedBox(height: 8.0)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final ownedBusiness = currentUserDocument!.ownedBusiness!;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      floatingActionButton: const SupportBubbleWidget(),
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: KinBackButton(),
        title: Text(
          'Growth Tools',
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ROI Dashboard - prominently displayed to drive tier upgrades.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: StreamBuilder<BusinessesRecord>(
                  stream: BusinessesRecord.getDocument(ownedBusiness),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox.shrink();
                    return OwnerROIDashboardWidget(
                      businessId: snapshot.data!.reference.id,
                      currentTier: snapshot.data!.subscriptionTier ?? 'free',
                    );
                  },
                ),
              ),
              // Promote - was a hamburger-menu row; a share action fits
              // better as a direct button on the page whose whole purpose
              // is growing the business.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 0.0),
                child: Builder(
                  builder: (builderContext) => FFButtonWidget(
                    onPressed: () async {
                      final business =
                          await BusinessesRecord.getDocumentOnce(ownedBusiness);
                      await KinServices.shareApp(
                        text: 'Check out ${business.businessName} on '
                            'KIN! Download the app: $kPlayStoreUrl',
                        sharePositionOrigin:
                            getWidgetBoundingBox(builderContext),
                        businessRef: ownedBusiness,
                      );
                      if (builderContext.mounted) {
                        showKindexEngagementNudge(builderContext);
                      }
                    },
                    text: 'Promote Your Business',
                    icon: Icon(Icons.share_rounded, size: 18.0),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48.0,
                      color: theme.primary,
                      textStyle:
                          theme.titleSmall.override(color: theme.onPrimary),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              // Active Promotion - Power Hour + Location Beacon.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: theme.primaryText, size: 18.0),
                        Text(
                          'Active Promotion',
                          style: theme.titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                            color: theme.primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: StreamBuilder<BusinessesRecord>(
                          stream: BusinessesRecord.getDocument(ownedBusiness),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.secondaryText),
                                  ),
                                ),
                              );
                            }
                            final business = snapshot.data!;
                            return PowerHourPanelWidget(
                              businessRef: business.reference,
                              hasFlashBeacon: business.hasFlashBeacon,
                              flashBeaconExpiresAt:
                                  business.flashBeaconExpiresAt,
                            );
                          },
                        ),
                      ),
                    ),
                    StreamBuilder<BusinessesRecord>(
                      stream: BusinessesRecord.getDocument(ownedBusiness),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(
                            height: 120.0,
                            child: Center(
                              child: SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.secondaryText),
                                ),
                              ),
                            ),
                          );
                        }
                        final business = snapshot.data!;
                        return LocationBeaconCardWidget(
                          businessRef: business.reference,
                          businessName: business.businessName,
                          isMobileVendor: business.isMobileVendor,
                          currentLocation: business.currentLocation,
                          expiresAt: business.currentLocationExpiresAt,
                          isActive: business.mobileLocationActive,
                        );
                      },
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              // Manage My Listings - My Items / Jobs (+ applicant messages) /
              // Events, one tap into the same sub-sheet Owner Profile used
              // to open from its hamburger menu.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 0.0),
                child: CompactActionListWidget(items: [
                  CompactActionRowData(
                    icon: Icons.storefront_rounded,
                    title: 'Manage My Listings',
                    subtitle: 'Items, jobs, and events you\'ve posted.',
                    onTap: () => _showManageListingsSheet(context),
                  ),
                ]),
              ),
              // Your Membership Tier.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Your Membership Tier',
                      style: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold),
                        color: theme.primaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Every tier's own card, not just the current one - a
                    // Community business used to see a single card with
                    // nothing but locked features and no way to see what
                    // stepping up would actually unlock. StreamBuilder
                    // wraps the whole comparison (not one card each) so
                    // all five stay in sync off one read.
                    StreamBuilder<BusinessesRecord>(
                      stream: BusinessesRecord.getDocument(ownedBusiness),
                      builder: (context, snapshot) {
                        final rawTierName = snapshot.hasData
                            ? snapshot.data!.subscriptionTier
                            : '';
                        final currentTier =
                            rawTierName.isEmpty ? 'Community' : rawTierName;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final cardTier in kSubscriptionTierOrder)
                              _tierComparisonCard(
                                  context, cardTier, currentTier),
                          ].divide(SizedBox(height: 12.0)),
                        );
                      },
                    ),
                    InkWell(
                      onTap: () => context.pushNamed(
                        MerchantPricingSuiteWidget.routeName,
                        queryParameters: {
                          'businessRef': serializeParam(
                            ownedBusiness,
                            ParamType.DocumentReference,
                          ),
                        }.withoutNulls,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'See full plan details & upgrade',
                          style: theme.bodyMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold),
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
              // Apple Guideline 3.1.2 requires a subscription app to link
              // out to where a plan can be managed or cancelled, and to
              // offer Restore Purchases.
              const SubscriptionManagementRow(),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 0.0),
                child: CompactActionListWidget(items: [
                  CompactActionRowData(
                    icon: Icons.auto_awesome_mosaic_rounded,
                    title: 'Need an app for your business?',
                    subtitle: 'Submit a brief through App Studio.',
                    onTap: () =>
                        context.pushNamed(AppStudioPageWidget.routeName),
                  ),
                ]),
              ),
              Container(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
