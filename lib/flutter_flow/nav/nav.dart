import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? Page3SanAntonioDiscoveryMapWidget()
          : Page1WelcomeMissionCopyWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? Page3SanAntonioDiscoveryMapWidget()
              : Page1WelcomeMissionCopyWidget(),
        ),
        FFRoute(
          name: HomeScreenWidget.routeName,
          path: HomeScreenWidget.routePath,
          builder: (context, params) => HomeScreenWidget(),
        ),
        FFRoute(
          name: MapScreenWidget.routeName,
          path: MapScreenWidget.routePath,
          builder: (context, params) => MapScreenWidget(),
        ),
        FFRoute(
          name: CommunityFeedWidget.routeName,
          path: CommunityFeedWidget.routePath,
          builder: (context, params) => CommunityFeedWidget(),
        ),
        FFRoute(
          name: LoyaltyDashboardWidget.routeName,
          path: LoyaltyDashboardWidget.routePath,
          builder: (context, params) => LoyaltyDashboardWidget(),
        ),
        FFRoute(
          name: WelcomeScreenWidget.routeName,
          path: WelcomeScreenWidget.routePath,
          builder: (context, params) => WelcomeScreenWidget(),
        ),
        FFRoute(
          name: CustomerSignUpWidget.routeName,
          path: CustomerSignUpWidget.routePath,
          builder: (context, params) => CustomerSignUpWidget(),
        ),
        FFRoute(
          name: PartnerSignUpWidget.routeName,
          path: PartnerSignUpWidget.routePath,
          builder: (context, params) => PartnerSignUpWidget(),
        ),
        FFRoute(
          name: BusinessDashboardWidget.routeName,
          path: BusinessDashboardWidget.routePath,
          builder: (context, params) => BusinessDashboardWidget(
            businessProfile: params.getParam(
              'businessProfile',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: BusinessManagerUpgradeWidget.routeName,
          path: BusinessManagerUpgradeWidget.routePath,
          builder: (context, params) => BusinessManagerUpgradeWidget(),
        ),
        FFRoute(
          name: NewScreen1Widget.routeName,
          path: NewScreen1Widget.routePath,
          builder: (context, params) => NewScreen1Widget(),
        ),
        FFRoute(
          name: BoostYourBusinessWidget.routeName,
          path: BoostYourBusinessWidget.routePath,
          builder: (context, params) => BoostYourBusinessWidget(),
        ),
        FFRoute(
          name: AdminDashboardWidget.routeName,
          path: AdminDashboardWidget.routePath,
          builder: (context, params) => AdminDashboardWidget(),
        ),
        FFRoute(
          name: TheKINAppWidget.routeName,
          path: TheKINAppWidget.routePath,
          builder: (context, params) => TheKINAppWidget(),
        ),
        FFRoute(
          name: WelcomeMissionFINALWidget.routeName,
          path: WelcomeMissionFINALWidget.routePath,
          builder: (context, params) => WelcomeMissionFINALWidget(),
        ),
        FFRoute(
          name: TheExchangeWidget.routeName,
          path: TheExchangeWidget.routePath,
          builder: (context, params) => TheExchangeWidget(),
        ),
        FFRoute(
          name: AgeVerificationSB2420Widget.routeName,
          path: AgeVerificationSB2420Widget.routePath,
          builder: (context, params) => AgeVerificationSB2420Widget(),
        ),
        FFRoute(
          name: BusinessOwnerRegistrationWidget.routeName,
          path: BusinessOwnerRegistrationWidget.routePath,
          builder: (context, params) => BusinessOwnerRegistrationWidget(),
        ),
        FFRoute(
          name: Page1WelcomeMissionWidget.routeName,
          path: Page1WelcomeMissionWidget.routePath,
          builder: (context, params) => Page1WelcomeMissionWidget(),
        ),
        FFRoute(
          name: CustomerSignUpStep1Widget.routeName,
          path: CustomerSignUpStep1Widget.routePath,
          builder: (context, params) => CustomerSignUpStep1Widget(),
        ),
        FFRoute(
          name: Page3SanAntonioDiscoveryMapWidget.routeName,
          path: Page3SanAntonioDiscoveryMapWidget.routePath,
          builder: (context, params) => Page3SanAntonioDiscoveryMapWidget(),
        ),
        FFRoute(
          name: CustomerSignUpStep2Widget.routeName,
          path: CustomerSignUpStep2Widget.routePath,
          builder: (context, params) => CustomerSignUpStep2Widget(),
        ),
        FFRoute(
          name: Page4MembershipPricingWidget.routeName,
          path: Page4MembershipPricingWidget.routePath,
          builder: (context, params) => Page4MembershipPricingWidget(),
        ),
        FFRoute(
          name: InvestorHubWidget.routeName,
          path: InvestorHubWidget.routePath,
          builder: (context, params) => InvestorHubWidget(),
        ),
        FFRoute(
          name: BusinessDashboard2Widget.routeName,
          path: BusinessDashboard2Widget.routePath,
          builder: (context, params) => BusinessDashboard2Widget(),
        ),
        FFRoute(
          name: Page1WelcomeMissionCopyWidget.routeName,
          path: Page1WelcomeMissionCopyWidget.routePath,
          builder: (context, params) => Page1WelcomeMissionCopyWidget(),
        ),
        FFRoute(
          name: PilotMainFlowWidget.routeName,
          path: PilotMainFlowWidget.routePath,
          builder: (context, params) => PilotMainFlowWidget(),
        ),
        FFRoute(
          name: TheExchange2Widget.routeName,
          path: TheExchange2Widget.routePath,
          builder: (context, params) => TheExchange2Widget(),
        ),
        FFRoute(
          name: AgeVerificationSB24202Widget.routeName,
          path: AgeVerificationSB24202Widget.routePath,
          builder: (context, params) => AgeVerificationSB24202Widget(),
        ),
        FFRoute(
          name: BusinessOwnerRegistration2Widget.routeName,
          path: BusinessOwnerRegistration2Widget.routePath,
          builder: (context, params) => BusinessOwnerRegistration2Widget(),
        ),
        FFRoute(
          name: CustomerSignUpStep12Widget.routeName,
          path: CustomerSignUpStep12Widget.routePath,
          builder: (context, params) => CustomerSignUpStep12Widget(),
        ),
        FFRoute(
          name: Page3SanAntonioDiscoveryMap2Widget.routeName,
          path: Page3SanAntonioDiscoveryMap2Widget.routePath,
          builder: (context, params) => Page3SanAntonioDiscoveryMap2Widget(),
        ),
        FFRoute(
          name: CustomerSignUpStep22Widget.routeName,
          path: CustomerSignUpStep22Widget.routePath,
          builder: (context, params) => CustomerSignUpStep22Widget(),
        ),
        FFRoute(
          name: Page4MembershipPricing2Widget.routeName,
          path: Page4MembershipPricing2Widget.routePath,
          builder: (context, params) => Page4MembershipPricing2Widget(),
        ),
        FFRoute(
          name: OnboardingStep1Widget.routeName,
          path: OnboardingStep1Widget.routePath,
          builder: (context, params) => OnboardingStep1Widget(),
        ),
        FFRoute(
          name: InvestorHub2Widget.routeName,
          path: InvestorHub2Widget.routePath,
          builder: (context, params) => InvestorHub2Widget(),
        ),
        FFRoute(
          name: BusinessDashboard3Widget.routeName,
          path: BusinessDashboard3Widget.routePath,
          builder: (context, params) => BusinessDashboard3Widget(),
        ),
        FFRoute(
          name: OnboardingStep2Widget.routeName,
          path: OnboardingStep2Widget.routePath,
          builder: (context, params) => OnboardingStep2Widget(),
        ),
        FFRoute(
          name: OnboardingStep3Widget.routeName,
          path: OnboardingStep3Widget.routePath,
          builder: (context, params) => OnboardingStep3Widget(),
        ),
        FFRoute(
          name: BusinessPreviewBottomSheetWidget.routeName,
          path: BusinessPreviewBottomSheetWidget.routePath,
          builder: (context, params) => BusinessPreviewBottomSheetWidget(),
        ),
        FFRoute(
          name: KINSpotlightWidget.routeName,
          path: KINSpotlightWidget.routePath,
          builder: (context, params) => KINSpotlightWidget(),
        ),
        FFRoute(
          name: GrowthImpactPitchWidget.routeName,
          path: GrowthImpactPitchWidget.routePath,
          builder: (context, params) => GrowthImpactPitchWidget(),
        ),
        FFRoute(
          name: VerifiedBadgeComponentWidget.routeName,
          path: VerifiedBadgeComponentWidget.routePath,
          builder: (context, params) => VerifiedBadgeComponentWidget(),
        ),
        FFRoute(
          name: Page1WelcomeMissionCopy2Widget.routeName,
          path: Page1WelcomeMissionCopy2Widget.routePath,
          builder: (context, params) => Page1WelcomeMissionCopy2Widget(),
        ),
        FFRoute(
          name: Page1WelcomeMission2Widget.routeName,
          path: Page1WelcomeMission2Widget.routePath,
          builder: (context, params) => Page1WelcomeMission2Widget(),
        ),
        FFRoute(
          name: Page1WelcomeMissionFINALWidget.routeName,
          path: Page1WelcomeMissionFINALWidget.routePath,
          builder: (context, params) => Page1WelcomeMissionFINALWidget(),
        ),
        FFRoute(
          name: Page1WelcomeFINALWidget.routeName,
          path: Page1WelcomeFINALWidget.routePath,
          builder: (context, params) => Page1WelcomeFINALWidget(),
        ),
        FFRoute(
          name: LocalGemsWidget.routeName,
          path: LocalGemsWidget.routePath,
          builder: (context, params) => LocalGemsWidget(),
        ),
        FFRoute(
          name: BusinessRFCMarketplaceWidget.routeName,
          path: BusinessRFCMarketplaceWidget.routePath,
          builder: (context, params) => BusinessRFCMarketplaceWidget(),
        ),
        FFRoute(
          name: AddBusinessPageWidget.routeName,
          path: AddBusinessPageWidget.routePath,
          builder: (context, params) => AddBusinessPageWidget(),
        ),
        FFRoute(
          name: BusinessVIPShowcaseWidget.routeName,
          path: BusinessVIPShowcaseWidget.routePath,
          builder: (context, params) => BusinessVIPShowcaseWidget(),
        ),
        FFRoute(
          name: BusinessActionsWidget.routeName,
          path: BusinessActionsWidget.routePath,
          asyncParams: {
            'activeBusiness':
                getDoc(['businesses'], BusinessesRecord.fromSnapshot),
          },
          builder: (context, params) => BusinessActionsWidget(
            activeBusiness: params.getParam(
              'activeBusiness',
              ParamType.Document,
            ),
          ),
        ),
        FFRoute(
          name: MarketplaceHomeWidget.routeName,
          path: MarketplaceHomeWidget.routePath,
          builder: (context, params) => MarketplaceHomeWidget(),
        ),
        FFRoute(
          name: VIPShowcaseWidget.routeName,
          path: VIPShowcaseWidget.routePath,
          asyncParams: {
            'activeBusiness':
                getDoc(['businesses'], BusinessesRecord.fromSnapshot),
          },
          builder: (context, params) => VIPShowcaseWidget(
            activeBusiness: params.getParam(
              'activeBusiness',
              ParamType.Document,
            ),
          ),
        ),
        FFRoute(
          name: MarketplaceHome2Widget.routeName,
          path: MarketplaceHome2Widget.routePath,
          builder: (context, params) => MarketplaceHome2Widget(),
        ),
        FFRoute(
          name: BusinessProfileWidget.routeName,
          path: BusinessProfileWidget.routePath,
          builder: (context, params) => BusinessProfileWidget(),
        ),
        FFRoute(
          name: MarketplacePremiumWidget.routeName,
          path: MarketplacePremiumWidget.routePath,
          builder: (context, params) => MarketplacePremiumWidget(),
        ),
        FFRoute(
          name: MarketplaceHome3Widget.routeName,
          path: MarketplaceHome3Widget.routePath,
          builder: (context, params) => MarketplaceHome3Widget(),
        ),
        FFRoute(
          name: VIPShowcase2Widget.routeName,
          path: VIPShowcase2Widget.routePath,
          builder: (context, params) => VIPShowcase2Widget(
            activeBusiness: params.getParam(
              'activeBusiness',
              ParamType.double,
            ),
          ),
        ),
        FFRoute(
          name: VIPShowcase3Widget.routeName,
          path: VIPShowcase3Widget.routePath,
          builder: (context, params) => VIPShowcase3Widget(
            activeBusiness: params.getParam(
              'activeBusiness',
              ParamType.double,
            ),
          ),
        ),
        FFRoute(
          name: Homescreen2Widget.routeName,
          path: Homescreen2Widget.routePath,
          builder: (context, params) => Homescreen2Widget(),
        ),
        FFRoute(
          name: VIPShowcaseFinalWidget.routeName,
          path: VIPShowcaseFinalWidget.routePath,
          builder: (context, params) => VIPShowcaseFinalWidget(),
        ),
        FFRoute(
          name: KINVIPFinalWidget.routeName,
          path: KINVIPFinalWidget.routePath,
          builder: (context, params) => KINVIPFinalWidget(),
        ),
        FFRoute(
          name: AdminDashboardFinalWidget.routeName,
          path: AdminDashboardFinalWidget.routePath,
          builder: (context, params) => AdminDashboardFinalWidget(),
        ),
        FFRoute(
          name: BusinessDirectoryWidget.routeName,
          path: BusinessDirectoryWidget.routePath,
          builder: (context, params) => BusinessDirectoryWidget(),
        ),
        FFRoute(
          name: BusinessCollectionWidget.routeName,
          path: BusinessCollectionWidget.routePath,
          builder: (context, params) => BusinessCollectionWidget(),
        ),
        FFRoute(
          name: FlashBenefitManagerWidget.routeName,
          path: FlashBenefitManagerWidget.routePath,
          builder: (context, params) => FlashBenefitManagerWidget(),
        ),
        FFRoute(
          name: DiscoverMapWidget.routeName,
          path: DiscoverMapWidget.routePath,
          builder: (context, params) => DiscoverMapWidget(),
        ),
        FFRoute(
          name: DestinationWidget.routeName,
          path: DestinationWidget.routePath,
          builder: (context, params) => DestinationWidget(),
        ),
        FFRoute(
          name: BizDirectoryWidget.routeName,
          path: BizDirectoryWidget.routePath,
          builder: (context, params) => BizDirectoryWidget(),
        ),
        FFRoute(
          name: BusinessProfile2Widget.routeName,
          path: BusinessProfile2Widget.routePath,
          builder: (context, params) => BusinessProfile2Widget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: BizDirectory2Widget.routeName,
          path: BizDirectory2Widget.routePath,
          builder: (context, params) => BizDirectory2Widget(),
        ),
        FFRoute(
          name: BusinessOnboardingWidget.routeName,
          path: BusinessOnboardingWidget.routePath,
          builder: (context, params) => BusinessOnboardingWidget(),
        ),
        FFRoute(
          name: SABizDirectoryWidget.routeName,
          path: SABizDirectoryWidget.routePath,
          builder: (context, params) => SABizDirectoryWidget(),
        ),
        FFRoute(
          name: BizSetupPageWidget.routeName,
          path: BizSetupPageWidget.routePath,
          builder: (context, params) => BizSetupPageWidget(),
        ),
        FFRoute(
          name: BizDirectory3Widget.routeName,
          path: BizDirectory3Widget.routePath,
          builder: (context, params) => BizDirectory3Widget(),
        ),
        FFRoute(
          name: MapScreen3Widget.routeName,
          path: MapScreen3Widget.routePath,
          builder: (context, params) => MapScreen3Widget(),
        ),
        FFRoute(
          name: OnboardingFormWidget.routeName,
          path: OnboardingFormWidget.routePath,
          builder: (context, params) => OnboardingFormWidget(),
        ),
        FFRoute(
          name: BusinessDetailPageWidget.routeName,
          path: BusinessDetailPageWidget.routePath,
          builder: (context, params) => BusinessDetailPageWidget(),
        ),
        FFRoute(
          name: OnboardingForm2Widget.routeName,
          path: OnboardingForm2Widget.routePath,
          builder: (context, params) => OnboardingForm2Widget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: BusinessOnboarding2Widget.routeName,
          path: BusinessOnboarding2Widget.routePath,
          builder: (context, params) => BusinessOnboarding2Widget(),
        ),
        FFRoute(
          name: LandingPageWidget.routeName,
          path: LandingPageWidget.routePath,
          builder: (context, params) => LandingPageWidget(),
        ),
        FFRoute(
          name: BusinessDirectory2Widget.routeName,
          path: BusinessDirectory2Widget.routePath,
          builder: (context, params) => BusinessDirectory2Widget(),
        ),
        FFRoute(
          name: BusinessDirectory3Widget.routeName,
          path: BusinessDirectory3Widget.routePath,
          builder: (context, params) => BusinessDirectory3Widget(),
        ),
        FFRoute(
          name: MobileSearchWidget.routeName,
          path: MobileSearchWidget.routePath,
          builder: (context, params) => MobileSearchWidget(),
        ),
        FFRoute(
          name: BusinessProfileTemplateWidget.routeName,
          path: BusinessProfileTemplateWidget.routePath,
          builder: (context, params) => BusinessProfileTemplateWidget(
            businessName: params.getParam(
              'businessName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: CardDraftPageWidget.routeName,
          path: CardDraftPageWidget.routePath,
          builder: (context, params) => CardDraftPageWidget(),
        ),
        FFRoute(
          name: BusinessSignUpWidget.routeName,
          path: BusinessSignUpWidget.routePath,
          builder: (context, params) => BusinessSignUpWidget(),
        ),
        FFRoute(
          name: LeadCaptureWidget.routeName,
          path: LeadCaptureWidget.routePath,
          builder: (context, params) => LeadCaptureWidget(),
        ),
        FFRoute(
          name: KindexFeedCardWidget.routeName,
          path: KindexFeedCardWidget.routePath,
          builder: (context, params) => KindexFeedCardWidget(),
        ),
        FFRoute(
          name: LegalPrivacyPageWidget.routeName,
          path: LegalPrivacyPageWidget.routePath,
          builder: (context, params) => LegalPrivacyPageWidget(),
        ),
        FFRoute(
          name: KINAnalyticsWidget.routeName,
          path: KINAnalyticsWidget.routePath,
          builder: (context, params) => KINAnalyticsWidget(),
        ),
        FFRoute(
          name: TheMembershipSuiteWidget.routeName,
          path: TheMembershipSuiteWidget.routePath,
          builder: (context, params) => TheMembershipSuiteWidget(),
        ),
        FFRoute(
          name: KindexShowcaseWidget.routeName,
          path: KindexShowcaseWidget.routePath,
          builder: (context, params) => KindexShowcaseWidget(),
        ),
        FFRoute(
          name: AdminPulseWidget.routeName,
          path: AdminPulseWidget.routePath,
          builder: (context, params) => AdminPulseWidget(),
        ),
        FFRoute(
          name: BusinessPageWidget.routeName,
          path: BusinessPageWidget.routePath,
          builder: (context, params) => BusinessPageWidget(
            businessRecord: params.getParam(
              'businessRecord',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: BusinessInputFormPageWidget.routeName,
          path: BusinessInputFormPageWidget.routePath,
          builder: (context, params) => BusinessInputFormPageWidget(),
        ),
        FFRoute(
          name: ProfessionalPrivacyPolicyPageWidget.routeName,
          path: ProfessionalPrivacyPolicyPageWidget.routePath,
          builder: (context, params) => ProfessionalPrivacyPolicyPageWidget(),
        ),
        FFRoute(
          name: TermsOfServicePageWidget.routeName,
          path: TermsOfServicePageWidget.routePath,
          builder: (context, params) => TermsOfServicePageWidget(),
        ),
        FFRoute(
          name: DarkThemedMobilePageWidget.routeName,
          path: DarkThemedMobilePageWidget.routePath,
          builder: (context, params) => DarkThemedMobilePageWidget(),
        ),
        FFRoute(
          name: BusinessWelcomeWidget.routeName,
          path: BusinessWelcomeWidget.routePath,
          builder: (context, params) => BusinessWelcomeWidget(),
        ),
        FFRoute(
          name: CinematicHighContrastPageWidget.routeName,
          path: CinematicHighContrastPageWidget.routePath,
          builder: (context, params) => CinematicHighContrastPageWidget(),
        ),
        FFRoute(
          name: SleekPowerfulBackgroundPageWidget.routeName,
          path: SleekPowerfulBackgroundPageWidget.routePath,
          builder: (context, params) => SleekPowerfulBackgroundPageWidget(),
        ),
        FFRoute(
          name: PremiumMobileUserPageWidget.routeName,
          path: PremiumMobileUserPageWidget.routePath,
          builder: (context, params) => PremiumMobileUserPageWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/page1WelcomeMissionCopy';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Container(
                  color: Colors.transparent,
                  child: Image.asset(
                    'assets/images/Untitled_design_(1).png',
                    fit: BoxFit.cover,
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
