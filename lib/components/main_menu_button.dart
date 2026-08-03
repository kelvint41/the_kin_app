import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/kin_services.dart';
import '/services/feature_flags.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// The app's hamburger menu button - shown on every top-level page (Map,
/// Owner Profile, Customer Profile, The Exchange, Nearby Feed). Originally
/// lived only on the map page; extracted here so every top-level page can
/// share one implementation instead of forking the sheet.
///
/// [extraItems] lets a page append its own actions after the standard
/// role-adaptive items and before the final Sign Out row - Owner Profile
/// uses this for its Setup/Promote/Preview/Get Support/My Items/Dashboard
/// actions, which used to be a separate button row on the page itself.
class MainMenuButton extends StatelessWidget {
  const MainMenuButton({super.key, this.extraItems = const []});

  final List<Widget> extraItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
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
          color: FlutterFlowTheme.of(context).primaryText,
          size: 24.0,
        ),
        onPressed: () => showMainMenuSheet(context, extraItems: extraItems),
      ),
    );
  }
}

/// The hamburger menu's bottom sheet: The Exchange / Marketplace / My Business
/// (or My Profile) / Business Insights (or The KIN Quest), then any
/// page-specific [extraItems], then Sign Out (or Sign In). The Exchange
/// requires a real businessRef, so it's the only item gated on actually
/// owning a business - My Business self-guards internally (OwnerProfileWidget
/// already shows its own "set up your business" empty state).
void showMainMenuSheet(BuildContext context,
    {List<Widget> extraItems = const []}) {
  final theme = FlutterFlowTheme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    // The base 4 items plus a page's extraItems (Owner Profile alone adds
    // up to 6, 7 for admins) plus the divider and sign-out row can add up
    // to more than the screen's height. A plain, non-scrollable Column
    // here doesn't clip or scroll past that - it silently overflows, with
    // the bottom rows (Get Support, My Items, Sign Out) rendered off the
    // bottom of the screen and unreachable. isScrollControlled plus the
    // SingleChildScrollView/ConstrainedBox below let it scroll instead.
    isScrollControlled: true,
    builder: (sheetContext) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(theme.designToken.radius.lg),
              topRight: Radius.circular(theme.designToken.radius.lg),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
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
                      leading: Icon(Icons.map_outlined, color: theme.primaryText),
                      title: Text('Map', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(GoogleMapPageWidget.routeName);
                      },
                    ),
                    // Hidden while the social layer is unfinished. The
                    // route is gated too (see nav.dart) - this just stops
                    // anyone tapping into a Coming Soon screen.
                    if (FeatureFlags.exchangeEnabled)
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
                    // Always visible, not role-adaptive - Marketplace is
                    // discovery for everyone, same as the map itself. No
                    // auth required, matching MarketplaceWidget's public route.
                    ListTile(
                      leading: Icon(Icons.storefront_outlined,
                          color: theme.primaryText),
                      title: Text('Marketplace', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(MarketplaceWidget.routeName);
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
                    ListTile(
                      leading:
                          Icon(Icons.work_outline_rounded, color: theme.primaryText),
                      title: Text('Job Board', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(JobBoardListingPage.routeName);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.volunteer_activism_outlined,
                          color: theme.primaryText),
                      title: Text('Community Events', style: theme.bodyLarge),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.pushNamed(EventsListingPage.routeName);
                      },
                    ),
                    ...extraItems,
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
                        leading: Icon(Icons.logout_rounded, color: theme.error),
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
                          confirmSignOut(context);
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
          ),
        ),
      );
    },
  );
}

/// Confirm-gated, matching how Power Hour's stop button is gated: sign-out
/// sits one tap away from several navigation items, and an accidental
/// sign-out strands someone until they remember their password.
Future<void> confirmSignOut(BuildContext context) async {
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
  if (confirmed != true || !context.mounted) return;

  // The router rebuilds on an auth change unless it's told one is coming,
  // which would interrupt the navigation below. See
  // AppStateNotifier.updateNotifyOnAuthChange.
  GoRouter.of(context).prepareAuthEvent();

  final result = await KinServices.signOut();
  if (!context.mounted) return;

  if (!result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error!)),
    );
    return;
  }
  context.goNamedAuth(SignInPageWidget.routeName, context.mounted);
}
