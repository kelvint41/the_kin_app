import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

export 'package:purchases_flutter/purchases_flutter.dart'
    show Package, Offering;

Offerings? _offerings;
CustomerInfo? _customerInfo;
String? _loggedInUid;
bool _isConfigured = false;

Offerings? get offerings => _offerings;
CustomerInfo? get customerInfo => _customerInfo;
bool get isConfigured => _isConfigured;

set customerInfo(CustomerInfo? customerInfo) => _customerInfo = customerInfo;

Future initialize(
  String appStoreKey,
  String playStoreKey, {
  String webKey = '',
  bool debugLogEnabled = false,
  bool loadDataAfterLaunch = false,
}) async {
  try {
    // Set log level before configuration
    await Purchases.setLogLevel(
      debugLogEnabled ? LogLevel.debug : LogLevel.info,
    );

    // Configure based on platform
    PurchasesConfiguration configuration;
    String platformKey;
    if (kIsWeb) {
      if (webKey.isEmpty) {
        print(
          'RevenueCat web support requires a web API key. '
          'RevenueCat features will be disabled in Test Mode.',
        );
        return;
      }
      platformKey = webKey;
    } else if (Platform.isIOS) {
      platformKey = appStoreKey;
    } else if (Platform.isAndroid) {
      platformKey = playStoreKey;
    } else {
      print("RevenueCat is not supported on this platform.");
      return;
    }

    // Never hand RevenueCat a `test_` key. Its SDK treats a test key in a
    // release build as a security problem and *terminates the app on
    // launch* - which made the release APK unusable for testing anything
    // at all, not just purchases. Debug builds were unaffected, so this
    // only surfaced on the first real Android build.
    //
    // Skipping costs nothing: a test key has no offering behind it, so
    // purchasePackage already found nothing and every upgrade button
    // already no-opped. This just makes "payments aren't set up yet"
    // degrade quietly instead of taking the whole app down with it.
    // _isConfigured stays false, which callers already handle.
    //
    // Real keys arrive via --dart-define (see main.dart) once the products
    // exist in App Store Connect / Play Console.
    if (platformKey.isEmpty || platformKey.startsWith('test_')) {
      print(
        'RevenueCat has no production API key for this platform - '
        'purchases are disabled. Pass REVENUECAT_APPLE_KEY / '
        'REVENUECAT_GOOGLE_KEY at build time to enable them.',
      );
      return;
    }
    configuration = PurchasesConfiguration(platformKey);

    await Purchases.configure(configuration);
    _isConfigured = true;

    if (loadDataAfterLaunch) {
      loadCustomerInfo();
      loadOfferings();
    } else {
      await loadCustomerInfo();
      await loadOfferings();
    }

    Purchases.addCustomerInfoUpdateListener((info) {
      customerInfo = info;
    });
  } on Exception catch (e) {
    print("RevenueCat initialization failed: $e");
  }
}

// Purchase a package.
Future<bool> purchasePackage(String package) async {
  if (!_isConfigured) {
    print('RevenueCat is not configured. Cannot purchase package.');
    return false;
  }
  try {
    final revenueCatPackage = offerings?.current?.getPackage(package);
    if (revenueCatPackage == null) {
      return false;
    }
    // v9.0+: purchasePackage returns PurchaseResult instead of CustomerInfo
    final result = await Purchases.purchasePackage(revenueCatPackage);
    customerInfo = result.customerInfo;
    return true;
  } catch (_) {
    return false;
  }
}

List<String> get activeEntitlementIds => _customerInfo != null
    ? _customerInfo!.entitlements.active.values
        .map((e) => e.identifier)
        .toList()
    : [];

/// The real, localised store price for [packageId], or null when offerings
/// aren't loaded.
///
/// The pricing page displayed hardcoded strings - `price: '\$59'` and so on -
/// while the amount actually charged came from App Store Connect and Google
/// Play through RevenueCat. Nothing kept the two in step, so the app could
/// advertise one price and charge another: a store-review problem, a trust
/// problem, and wrong for every customer outside the US, who saw a US dollar
/// figure and was billed in their own currency.
///
/// This is the store's own price string, already localised and formatted by
/// the platform. Callers fall back to their literal when it returns null,
/// which is the case before offerings load and on any device with no store
/// connection - the Simulator included.
String? storePriceFor(String packageId) {
  try {
    return _offerings?.current?.getPackage(packageId)?.storeProduct.priceString;
  } catch (_) {
    return null;
  }
}

Future loadOfferings() async {
  if (!_isConfigured) {
    return;
  }
  try {
    _offerings = await Purchases.getOfferings();
  } on PlatformException catch (e) {
    print("Error loading offerings info: $e");
  }
}

Future loadCustomerInfo() async {
  if (!_isConfigured) {
    return;
  }
  try {
    _customerInfo = await Purchases.getCustomerInfo();
  } on PlatformException catch (e) {
    print("Error loading purchaser info: $e");
  }
}

// Return if the user has the entitlement.
// Return null on errors.
// Returns false if RevenueCat is not configured (e.g., no web billing key in Test Mode).
Future<bool?> isEntitled(String entitlementId) async {
  if (!_isConfigured) {
    // Return false instead of null to indicate no entitlement when unconfigured.
    // This allows Test Mode to work without a web billing key.
    return false;
  }
  try {
    customerInfo = await Purchases.getCustomerInfo();
    return customerInfo!.entitlements.all[entitlementId]?.isActive ?? false;
  } on Exception catch (e) {
    print("Unable to check RevenueCat entitlements: $e");
    return null;
  }
}

// https://docs.revenuecat.com/docs/user-ids
Future login(String? uid) async {
  if (!_isConfigured) {
    return;
  }
  if (uid == _loggedInUid) {
    return;
  }
  try {
    if (uid != null) {
      customerInfo = (await Purchases.logIn(uid)).customerInfo;
    } else {
      customerInfo = await Purchases.logOut();
    }
    _loggedInUid = uid;
  } on Exception catch (e) {
    print("Unable to logIn or logOut user in RevenueCat: $e");
  }
}

// https://docs.revenuecat.com/docs/restoring-purchases
Future restorePurchases() async {
  if (!_isConfigured) {
    return;
  }
  // Note: On web, purchases are automatically restored by Web Billing.
  // This method is only needed for iOS/Android.
  if (kIsWeb) {
    print(
      'Restore purchases is not needed on web - Web Billing handles this automatically.',
    );
    return;
  }
  try {
    customerInfo = await Purchases.restorePurchases();
  } on PlatformException catch (e) {
    print("Unable to restore purchases in RevenueCat: $e");
  }
}
