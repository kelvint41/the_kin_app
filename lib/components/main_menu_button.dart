import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/feedback_sheet_widget.dart';
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

/// A small caption-style header above a group of menu items (Discover,
/// Community, Quest, Profile) - lighter weight than [SectionHeaderWidget],
/// which is sized for a full page rather than a compact bottom sheet row.
///
/// Bold and underlined (rather than the previous plain semi-bold caption)
/// specifically to read as a visible divider between the four groups -
/// on a wider sheet (iPad) with the menu now stretched full-width, an
/// unbroken run of similarly-weighted ListTiles made it hard to tell where
/// one category ended and the next began.
Widget _sectionLabel(FlutterFlowTheme theme, String label) => Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 4.0),
      child: Text(
        label.toUpperCase(),
        style: theme.labelSmall.override(
          color: theme.secondaryText,
          letterSpacing: 0.5,
          fontWeight: FontWeight.bold,
          // No decorationColor override needed - TextDecoration inherits
          // the TextStyle's own color (secondaryText) by default.
          decoration: TextDecoration.underline,
        ),
      ),
    );

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
          // Explicit full width rather than sizing to content - on a wider
          // canvas (iPad) the Column below used to size itself to its
          // widest child instead of filling the sheet, so the whole menu
          // floated centered in the middle of the screen instead of
          // hugging the left edge.
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(theme.designToken.radius.lg),
              topRight: Radius.circular(theme.designToken.radius.lg),
            ),
          ),
          // A Material re-established here, not just relied-on from
          // showModalBottomSheet's own (transparent) one further up - the
          // Container above paints an opaque background between that outer
          // Material and every ListTile below, which is exactly the
          // "background is hidden" ListTile assertion Crashlytics was
          // catching in production: ListTile paints its ink/ripple on the
          // nearest Material ancestor, but this Container's opaque color
          // sits on top of that same distant Material, so the ink would be
          // invisible. transparent here so the Container's own rounded
          // sheet background still shows through underneath everything.
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: theme.designToken.spacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // Stretch so every row (section label, ListTile) fills
                    // the sheet's full width and left-aligns its content,
                    // instead of the Column's default center alignment
                    // hugging each row to its own intrinsic width.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40.0,
                          height: 4.0,
                          margin: EdgeInsets.only(
                              bottom: theme.designToken.spacing.md),
                          decoration: BoxDecoration(
                            color: theme.alternate,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                      // Grouped under labeled sections (Discover / Community /
                      // Quest / Profile) rather than one flat list of 9+ items
                      // - same destinations, same role-adaptive logic, just
                      // organized so the menu reads as a few clear categories
                      // instead of a wall of rows. Mirrors the customer bottom
                      // nav's own Home/Directory/Feed/Loyalty groupings, which
                      // this deliberately doesn't touch.
                      _sectionLabel(theme, 'Discover'),
                      ListTile(
                        leading:
                            Icon(Icons.map_outlined, color: theme.primaryText),
                        title: Text('Map', style: theme.bodyLarge),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.pushNamed(GoogleMapPageWidget.routeName);
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
                      _sectionLabel(theme, 'Community'),
                      // Hidden while the social layer is unfinished. The
                      // route is gated too (see nav.dart) - this just stops
                      // anyone tapping into a Coming Soon screen.
                      if (FeatureFlags.exchangeEnabled)
                        ListTile(
                          leading: Icon(Icons.forum_outlined,
                              color: theme.primaryText),
                          title: Text('The Exchange', style: theme.bodyLarge),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            // No longer gated on owning a business. The Exchange
                            // is a global feed that anyone can read and post to,
                            // so requiring a business here turned the menu item
                            // into a no-op with a snackbar for every customer -
                            // most of the people it exists for. A null ref just
                            // means posts carry no business tag.
                            final businessRef =
                                currentUserDocument?.ownedBusiness;
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
                      ListTile(
                        leading: Icon(Icons.volunteer_activism_outlined,
                            color: theme.primaryText),
                        title: Text('Community Events', style: theme.bodyLarge),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.pushNamed(EventsListingPage.routeName);
                        },
                      ),
                      _sectionLabel(theme, 'Quest'),
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
                      // The dark/light map redesign of KIN Quest - real
                      // businesses nearby (QuestEligibility.
                      // questEligibleBusinesses, same source the list-based
                      // KinQuestWidget uses) and real GPS, not the
                      // Georgia/Illinois test batch this used to be pinned
                      // to during development.
                      ListTile(
                        leading:
                            Icon(Icons.map_rounded, color: theme.primaryText),
                        title: Text('KIN Quest Map', style: theme.bodyLarge),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.pushNamed(KinQuestMapDemoWidget.routeName);
                        },
                      ),
                      _sectionLabel(theme, 'Profile'),
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
                      // Same role-branch as the row above, but the
                      // destination is the same widget either way -
                      // KindexScoreHistoryWidget renders the owner's
                      // business history when given a businessDocument and
                      // the signed-in customer's own history when not (see
                      // its class doc). An owner still has a personal
                      // customer-side Kindex too, but their business's score
                      // is what they came to this menu to check.
                      ListTile(
                        leading: Icon(Icons.show_chart_rounded,
                            color: theme.primaryText),
                        title: Text('My Kindex', style: theme.bodyLarge),
                        onTap: () {
                          final businessRef =
                              currentUserDocument?.ownedBusiness;
                          Navigator.pop(sheetContext);
                          context.pushNamed(
                            KindexScoreHistoryWidget.routeName,
                            queryParameters: {
                              'businessDocument': serializeParam(
                                businessRef,
                                ParamType.DocumentReference,
                              ),
                            }.withoutNulls,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.work_outline_rounded,
                            color: theme.primaryText),
                        title: Text('Job Board', style: theme.bodyLarge),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.pushNamed(JobBoardListingPage.routeName);
                        },
                      ),
                      // Universal rather than threaded onto individual pages -
                      // this menu is the one thing every page already shares,
                      // so it's the fastest way to put feedback within reach
                      // everywhere at once. originPage is the route the menu
                      // was opened from, not a hardcoded per-page string, so
                      // it stays correct with zero per-page wiring.
                      ListTile(
                        leading: Icon(Icons.chat_bubble_outline_rounded,
                            color: theme.primaryText),
                        title: Text('Send Feedback', style: theme.bodyLarge),
                        onTap: () {
                          final originPage =
                              GoRouterState.of(context).uri.toString();
                          Navigator.pop(sheetContext);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                FeedbackSheetWidget(originPage: originPage),
                          );
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
                            confirmSignOut(context);
                          },
                        ),
                      if (loggedIn)
                        ListTile(
                          leading: Icon(Icons.delete_outline_rounded,
                              color: theme.secondaryText),
                          title: Text(
                            'Delete Account',
                            style: theme.bodyLarge
                                .override(color: theme.secondaryText),
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            confirmDeleteAccount(context);
                          },
                        )
                      else
                        ListTile(
                          leading: Icon(Icons.login_rounded,
                              color: theme.primaryText),
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

/// Same confirm-then-act shape as [confirmSignOut], but for permanent
/// account deletion - the warning copy is explicit that this can't be
/// undone, and the confirm button reads DELETE rather than a euphemism.
Future<void> confirmDeleteAccount(BuildContext context) async {
  final theme = FlutterFlowTheme.of(context);
  final email = currentUserEmail;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.secondaryBackground,
      title: Text('Delete account?', style: theme.titleMedium),
      content: Text(
        (email.isEmpty
                ? 'This will permanently delete your account'
                : 'This will permanently delete $email') +
            ' - your profile, reviews, and check-in history. '
                'This action is permanent and cannot be undone.',
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
            'Delete',
            style: theme.bodyMedium.override(color: theme.error),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  GoRouter.of(context).prepareAuthEvent();

  await authManager.deleteUser(context);
  if (!context.mounted) return;

  // deleteUser() swallows its own error (e.g. requires-recent-login) and
  // shows a SnackBar rather than throwing, so success is read back from
  // auth state instead of a return value: Firebase signs the user out as
  // part of a successful delete, so still being logged in means it failed
  // and there's nothing to navigate away from.
  if (loggedIn) return;

  context.goNamedAuth(SignInPageWidget.routeName, context.mounted);
}
