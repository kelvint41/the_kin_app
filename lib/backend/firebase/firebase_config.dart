import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAGBadHybbKbE9TzOjzVnbGwFR_vOrpxXY",
            authDomain: "kinvest-build-app.firebaseapp.com",
            projectId: "kinvest-build-app",
            storageBucket: "kinvest-build-app.firebasestorage.app",
            messagingSenderId: "905088387635",
            appId: "1:905088387635:web:900c1dd0d5f6b4d89bf146",
            measurementId: "G-JTGYY4E879"));
  } else {
    await Firebase.initializeApp();
  }
}
