import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/auth/base_auth_user_provider.dart';

import '/main.dart';
import '/components/kin_splash_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

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

/// Set by main.dart's debug-only dev-bypass sign-in (see
/// _maybeSignInDevBypass), via --dart-define=DEV_ROUTE=... - defaults to
/// the Business Sign Up page since a fresh dev account has no business
/// yet. When non-null and the dev account is signed in, `/` redirects
/// here instead of the normal post-login landing page, so you land on
/// whatever you're testing immediately after launch. Change the
/// DEV_ROUTE dart-define per run to point at a different test page -
/// no code edit needed. Always null in release/profile builds.
String? devBypassTargetRoute;

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      redirect: (context, state) {
        // devBypassTargetRoute is only ever set after a real sign-in
        // succeeds (see main.dart's _maybeSignInDevBypass), so it's
        // already a reliable signal by itself - checking
        // appStateNotifier.loggedIn here too was redundant and raced
        // against its auth-stream listener, which isn't registered until
        // after this router is constructed and so still reads false on
        // the very first redirect evaluation.
        if (kDebugMode &&
            devBypassTargetRoute != null &&
            state.uri.path == '/') {
          return devBypassTargetRoute;
        }
        return null;
      },
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? GoogleMapPageWidget()
          : OnboardingSelectionCardWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? GoogleMapPageWidget()
              : OnboardingSelectionCardWidget(),
        ),
        FFRoute(
          name: TheExchangeWidget.routeName,
          path: TheExchangeWidget.routePath,
          requireAuth: true,
          builder: (context, params) => TheExchangeWidget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: KINVIPFinalWidget.routeName,
          path: KINVIPFinalWidget.routePath,
          builder: (context, params) => KINVIPFinalWidget(),
        ),
        FFRoute(
          name: BusinessSignUpWidget.routeName,
          path: BusinessSignUpWidget.routePath,
          builder: (context, params) => BusinessSignUpWidget(),
        ),
        FFRoute(
          name: PrivacyPolicyPageWidget.routeName,
          path: PrivacyPolicyPageWidget.routePath,
          builder: (context, params) => PrivacyPolicyPageWidget(),
        ),
        FFRoute(
          name: OnboardingSelectionCardWidget.routeName,
          path: OnboardingSelectionCardWidget.routePath,
          builder: (context, params) => OnboardingSelectionCardWidget(),
        ),
        FFRoute(
          name: BusinessProfileV2Widget.routeName,
          path: BusinessProfileV2Widget.routePath,
          builder: (context, params) => BusinessProfileV2Widget(
            businessDocument: params.getParam(
              'businessDocument',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          // Same requireAuth as TheExchange - this is the same content, just
          // aggregated across nearby businesses.
          name: NearbyFeedWidget.routeName,
          path: NearbyFeedWidget.routePath,
          requireAuth: true,
          builder: (context, params) => NearbyFeedWidget(),
        ),
        FFRoute(
          name: ClaimBusinessWidget.routeName,
          path: ClaimBusinessWidget.routePath,
          builder: (context, params) => ClaimBusinessWidget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: BusinessProfileOwnerWidget.routeName,
          path: BusinessProfileOwnerWidget.routePath,
          builder: (context, params) => BusinessProfileOwnerWidget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: MerchantPricingSuiteWidget.routeName,
          path: MerchantPricingSuiteWidget.routePath,
          builder: (context, params) => MerchantPricingSuiteWidget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
          ),
        ),
        FFRoute(
          name: TermsOfServicePageWidget.routeName,
          path: TermsOfServicePageWidget.routePath,
          builder: (context, params) => TermsOfServicePageWidget(),
        ),
        FFRoute(
          name: PartnerLOIPageWidget.routeName,
          path: PartnerLOIPageWidget.routePath,
          builder: (context, params) => PartnerLOIPageWidget(),
        ),
        FFRoute(
          name: DeliveryStatusWidget.routeName,
          path: DeliveryStatusWidget.routePath,
          builder: (context, params) => DeliveryStatusWidget(),
        ),
        FFRoute(
          name: MerchantSuccessScreenWidget.routeName,
          path: MerchantSuccessScreenWidget.routePath,
          builder: (context, params) => MerchantSuccessScreenWidget(),
        ),
        FFRoute(
          name: ProfessionalLandingPageWidget.routeName,
          path: ProfessionalLandingPageWidget.routePath,
          builder: (context, params) => ProfessionalLandingPageWidget(),
        ),
        FFRoute(
          name: AppBuilder1Widget.routeName,
          path: AppBuilder1Widget.routePath,
          builder: (context, params) => AppBuilder1Widget(),
        ),
        FFRoute(
          name: FullyFunctionalPremiumPageWidget.routeName,
          path: FullyFunctionalPremiumPageWidget.routePath,
          builder: (context, params) => FullyFunctionalPremiumPageWidget(),
        ),
        FFRoute(
          name: BusinessSetupPageWidget.routeName,
          path: BusinessSetupPageWidget.routePath,
          builder: (context, params) => BusinessSetupPageWidget(),
        ),
        FFRoute(
          name: GoogleMapPageWidget.routeName,
          path: GoogleMapPageWidget.routePath,
          builder: (context, params) => GoogleMapPageWidget(),
        ),
        FFRoute(
          name: ExecutiveDashboardWidget.routeName,
          path: ExecutiveDashboardWidget.routePath,
          builder: (context, params) => ExecutiveDashboardWidget(),
        ),
        FFRoute(
          name: CustomerProfilePageWidget.routeName,
          path: CustomerProfilePageWidget.routePath,
          builder: (context, params) => CustomerProfilePageWidget(
            businessRef: params.getParam(
              'businessRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['businesses'],
            ),
            scrollToMilestones: params.getParam(
                  'scrollToMilestones',
                  ParamType.bool,
                ) ??
                false,
          ),
        ),
        FFRoute(
          name: OwnerProfileWidget.routeName,
          path: OwnerProfileWidget.routePath,
          builder: (context, params) => OwnerProfileWidget(),
        ),
        FFRoute(
          name: CommunityPrestigeWidget.routeName,
          path: CommunityPrestigeWidget.routePath,
          builder: (context, params) => CommunityPrestigeWidget(),
        ),
        FFRoute(
          name: SignInPageWidget.routeName,
          path: SignInPageWidget.routePath,
          builder: (context, params) => SignInPageWidget(),
        ),
        FFRoute(
          name: CleanPremiumDarkPageWidget.routeName,
          path: CleanPremiumDarkPageWidget.routePath,
          builder: (context, params) => CleanPremiumDarkPageWidget(),
        ),
        FFRoute(
          name: CustomersignupPageWidget.routeName,
          path: CustomersignupPageWidget.routePath,
          builder: (context, params) => CustomersignupPageWidget(),
        ),
        FFRoute(
          name: MobileSignUpPageWidget.routeName,
          path: MobileSignUpPageWidget.routePath,
          builder: (context, params) => MobileSignUpPageWidget(),
        ),
        FFRoute(
          name: MobileCalledPowerPageWidget.routeName,
          path: MobileCalledPowerPageWidget.routePath,
          builder: (context, params) => MobileCalledPowerPageWidget(),
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
    StructBuilder<T>? structBuilder,
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
      structBuilder: structBuilder,
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
            return '/onboardingSelectionCard';
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
          final child =
              appStateNotifier.loading ? const KinSplashWidget() : page;

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
