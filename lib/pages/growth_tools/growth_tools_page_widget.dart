import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/kin_services.dart';
import '/services/subscription_tiers.dart';
import '/components/kin_back_button.dart';
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
                        Icon(Icons.storefront_rounded, color: theme.primaryText),
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
        );
      },
    );
  }

  /// The three benefit rows under "Your Membership Tier" - see
  /// kSubscriptionTierOrder (subscription_tiers.dart) for the ladder these
  /// minimums are checked against.
  Widget _tierFeatureRow(
      BuildContext context, String label, bool included) {
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

  Widget _tierFeatureList(BuildContext context, String tierName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tierFeatureRow(context, 'Priority KINDEX Ranking',
            tierAtLeast(tierName, 'Founder')),
        _tierFeatureRow(context, 'Unlimited Promotions',
            tierAtLeast(tierName, 'Premium Local')),
        _tierFeatureRow(context, 'Advanced Performance Analytics',
            tierAtLeast(tierName, 'Premium Local')),
      ].divide(SizedBox(height: 8.0)),
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () => _showManageListingsSheet(context),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: theme.alternate, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: theme.accentOnSurface, size: 22.0),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage My Listings',
                                  style: theme.bodyMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Items, jobs, and events you\'ve posted.',
                                  style: theme.bodySmall.override(
                                    font: GoogleFonts.plusJakartaSans(),
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.secondaryText, size: 20.0),
                      ],
                    ),
                  ),
                ),
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
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.primary, const Color(0xFF06251B)],
                            stops: [0.0, 1.0],
                            begin: AlignmentDirectional(1.0, 1.0),
                            end: AlignmentDirectional(-1.0, -1.0),
                          ),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: theme.accent1.withAlpha(51),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.accent1.withAlpha(51),
                                  borderRadius: BorderRadius.circular(9999.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 4.0, 16.0, 4.0),
                                  child: Text(
                                    'CURRENT PLAN',
                                    style: theme.labelSmall.override(
                                      font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold),
                                      color: const Color(0xFFD4AF37),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      lineHeight: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              StreamBuilder<BusinessesRecord>(
                                stream:
                                    BusinessesRecord.getDocument(ownedBusiness),
                                builder: (context, snapshot) {
                                  final rawTierName = snapshot.hasData
                                      ? snapshot.data!.subscriptionTier
                                      : '';
                                  final tierName = rawTierName.isEmpty
                                      ? 'Community'
                                      : rawTierName;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tierName,
                                        style: theme.headlineSmall.override(
                                          font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.bold),
                                          color: const Color(0xFFD4AF37),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _tierFeatureList(context, tierName),
                                    ].divide(SizedBox(height: 16.0)),
                                  );
                                },
                              ),
                            ].divide(SizedBox(height: 24.0)),
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () =>
                      context.pushNamed(AppStudioPageWidget.routeName),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: theme.alternate, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_mosaic_rounded,
                            color: theme.accentOnSurface, size: 22.0),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need an app for your business?',
                                  style: theme.bodyMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Submit a brief through App Studio.',
                                  style: theme.bodySmall.override(
                                    font: GoogleFonts.plusJakartaSans(),
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.secondaryText, size: 20.0),
                      ],
                    ),
                  ),
                ),
              ),
              Container(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
