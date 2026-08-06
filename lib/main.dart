import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/backend.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/kindex_ticker_util.dart';
import '/services/kin_services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'flutter_flow/revenue_cat_util.dart' as revenue_cat;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();
  _maybeUseFirebaseEmulator();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  // Real keys come from RevenueCat's dashboard (Project settings > API keys)
  // once the founding_local/pro_growth/elite_growth products exist in App
  // Store Connect and Google Play Console and are attached to a RevenueCat
  // offering. Pass them at build time so they never get checked into source:
  //   flutter build ... --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
  //                      --dart-define=REVENUECAT_GOOGLE_KEY=goog_xxx
  // Falls back to the literal test key, which has no real offering behind
  // it, so purchasePackage finds nothing and every upgrade button no-ops.
  const appStoreKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'test_nlIQSnnGvtvhLZnWwgHRKoDnhsN',
  );
  const playStoreKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'test_nlIQSnnGvtvhLZnWwgHRKoDnhsN',
  );
  await revenue_cat.initialize(
    appStoreKey,
    playStoreKey,
    loadDataAfterLaunch: true,
  );

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  await _maybeSignInDevBypass();
  _maybeForceThemeMode();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

/// Points Firestore/Functions at the local Firebase Emulator Suite instead
/// of production, for testing the Mystery Reward System end-to-end without
/// touching real data. Off by default - only activates with:
///
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
///
/// Gated on kDebugMode for the same reason as the dev sign-in bypass below:
/// the branch is dead code (eliminated by the compiler) in release/profile
/// builds, so this can never point a real user's app at localhost.
void _maybeUseFirebaseEmulator() {
  const useEmulator =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  if (!kDebugMode || !useEmulator) return;

  final host = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2' // Android emulator's alias for the host machine's localhost
      : 'localhost';
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  debugPrint(
      'Using Firebase Emulator Suite at $host (Firestore :8080, Functions :5001)');
}

/// Debug-only auto sign-in for local testing, so you don't have to log in
/// manually every run. Gated on kDebugMode, a real compile-time constant -
/// this whole function is dead code (eliminated by the compiler) in
/// release/profile builds, so it can never activate for a real user.
///
/// No credentials are hardcoded here - DEV_PASSWORD has no default, so
/// the bypass silently no-ops unless you explicitly supply one:
///
///   flutter run -d chrome --dart-define=DEV_PASSWORD=yourTestPassword
///
/// DEV_EMAIL defaults to the test account kelvin@apptest.com; override
/// with --dart-define=DEV_EMAIL=... for a different one. DEV_ROUTE
/// controls where you land after sign-in (see devBypassTargetRoute in
/// nav.dart) - defaults to Owner Profile, override with
/// --dart-define=DEV_ROUTE=/somePagePath to point at a different test
/// page without any code change. A real test business is auto-created
/// for the account if it doesn't already own one (see
/// _ensureDevBypassBusiness), so Owner Profile's business-required
/// guard never blocks you from getting there.
Future<void> _maybeSignInDevBypass() async {
  if (!kDebugMode) return;
  const password = String.fromEnvironment('DEV_PASSWORD');
  if (password.isEmpty) return;

  const email =
      String.fromEnvironment('DEV_EMAIL', defaultValue: 'kelvin@apptest.com');
  const route =
      String.fromEnvironment('DEV_ROUTE', defaultValue: '/ownerProfile');

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('DevBypass sign-in failed: $e');
      return;
    }
  }
  await _ensureDevBypassBusiness();
  devBypassTargetRoute = route;
}

/// Ensures the dev-bypass account owns a real business, so the "set up
/// your business first" guard (owner_profile_widget.dart and anywhere
/// else that checks currentUserDocument.ownedBusiness) never blocks
/// testing, on any page - with no per-page changes needed, since every
/// page already reads the same currentUserDocument.ownedBusiness.
///
/// This creates a REAL Firestore business document, not an in-memory
/// mock: a fake/non-existent business reference would satisfy a
/// null-check but leave every page that actually reads business data
/// (name, tier, address, etc.) showing blank or broken fields. Runs
/// once - idempotent, since it only acts when ownedBusiness is unset,
/// whether from a prior bypass run or a real registration.
Future<void> _ensureDevBypassBusiness() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final userRef = UsersRecord.collection.doc(uid);
  final userDoc = await UsersRecord.getDocumentOnce(userRef);
  if (userDoc.ownedBusiness != null) return;

  try {
    final businessRef = BusinessesRecord.collection.doc();
    await businessRef.set(createBusinessesRecordData(
      ownerRef: userRef,
      businessName: 'Dev Test Business',
      businessType: 'Sole Proprietor',
      isBlackOwned: true,
      tickerSymbol: KindexTickerUtil.randomCandidate(),
      isVerified: false,
      isClaimed: true,
      subscriptionTier: 'Community',
      isPremium: false,
    ));
    await userRef.update(createUsersRecordData(ownedBusiness: businessRef));
    debugPrint('DevBypass: created test business ${businessRef.id} for $uid');
  } catch (e) {
    debugPrint('DevBypass: failed to create test business: $e');
  }
}

/// Debug-only forced theme, for deterministic screenshot automation (see
/// integration_test/app_screenshots_test.dart). System/user theme
/// preference is normally read from SharedPreferences via
/// FlutterFlowTheme.themeMode, which would make CI screenshots depend on
/// whatever the simulator's default appearance happens to be - this
/// forces a specific mode before the first frame renders instead.
///
///   flutter drive ... --dart-define=SCREENSHOT_THEME=dark
///
/// No-ops (and leaves themeMode at its normal system/persisted value)
/// unless both kDebugMode and SCREENSHOT_THEME are set.
void _maybeForceThemeMode() {
  if (!kDebugMode) return;
  const theme = String.fromEnvironment('SCREENSHOT_THEME');
  if (theme == 'light') {
    FlutterFlowTheme.saveThemeMode(ThemeMode.light);
  } else if (theme == 'dark') {
    FlutterFlowTheme.saveThemeMode(ThemeMode.dark);
  }
}

/// Snackbars are how every failure in this app reaches the user - validation
/// messages, service errors, the AI quota notice - and they were rendering
/// with Material's stock colours: a near-white bar with black text against a
/// near-black app. Pulling the surface out of the app's own palette makes an
/// error look like it belongs to the product rather than like a system
/// dialog that escaped.
///
/// Built from an explicit theme instance rather than FlutterFlowTheme.of()
/// because this runs while constructing ThemeData, before there is a context
/// whose brightness could be read.
SnackBarThemeData _snackBarTheme(FlutterFlowTheme theme) => SnackBarThemeData(
      backgroundColor: theme.secondaryBackground,
      contentTextStyle: TextStyle(color: theme.primaryText),
      actionTextColor: theme.accentOnSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.md),
      ),
    );

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((user) async {
    await revenue_cat.login(user?.uid);
    // Gate paid features on the store's actual entitlement state, not just
    // whatever the last successful purchase wrote to Firestore - closes the
    // gap where a lapsed/refunded subscription otherwise stays "premium"
    // forever because nothing else re-checks it.
    final businessRef = user?.ownedBusiness;
    if (businessRef != null) {
      await KinServices.reconcileSubscriptionEntitlement(businessRef);
    }
  });

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = theKINAppFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    // No timer here anymore - KinSplashWidget now dismisses itself (tap on
    // its "Tap to enter" CTA, or its own auto-continue fallback if no one
    // taps) via the onContinue callback nav.dart wires to
    // stopShowingSplashImage. That also fixes the reason this used to be
    // routed through addPostFrameCallback: counting the hold from
    // initState double-counted the stretch the engine spends on the native
    // launch screen before the splash is ever on screen. Starting the
    // widget's own timer from its initState has the same effect for free,
    // since that only runs once the widget is actually mounted and
    // rendering.
  }

  @override
  void dispose() {
    authUserSub.cancel();

    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'The KIN App',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        snackBarTheme: _snackBarTheme(LightModeTheme()),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        snackBarTheme: _snackBarTheme(DarkModeTheme()),
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
