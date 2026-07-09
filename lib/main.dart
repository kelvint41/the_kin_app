import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
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

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  await revenue_cat.initialize(
    "test_nlIQSnnGvtvhLZnWwgHRKoDnhsN",
    "test_nlIQSnnGvtvhLZnWwgHRKoDnhsN",
    loadDataAfterLaunch: true,
  );

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  await _maybeSignInDevBypass();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
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
/// nav.dart) - defaults to the Business Sign Up page, override with
/// --dart-define=DEV_ROUTE=/somePagePath to point at a different test
/// page without any code change.
Future<void> _maybeSignInDevBypass() async {
  if (!kDebugMode) return;
  const password = String.fromEnvironment('DEV_PASSWORD');
  if (password.isEmpty) return;

  const email =
      String.fromEnvironment('DEV_EMAIL', defaultValue: 'kelvin@apptest.com');
  // Literal, not BusinessSignUpWidget.routePath - String.fromEnvironment's
  // defaultValue must be a compile-time constant, and routePath is a
  // mutable static field. Keep this in sync if that route path changes.
  const route =
      String.fromEnvironment('DEV_ROUTE', defaultValue: '/businessSignUp');

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('DevBypass sign-in failed: $e');
      return;
    }
  }
  devBypassTargetRoute = route;
}

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

  final authUserSub = authenticatedUserStream.listen((user) {
    revenue_cat.login(user?.uid);
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
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
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
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
