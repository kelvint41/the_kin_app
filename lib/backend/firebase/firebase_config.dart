import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAVZWeY3-eI6y7DdVOtgKiuZAkyrDPjhFc",
            authDomain: "cs-poc-zmueu0dydq2css28xexjlfq.firebaseapp.com",
            projectId: "cs-poc-zmueu0dydq2css28xexjlfq",
            storageBucket: "cs-poc-zmueu0dydq2css28xexjlfq.firebasestorage.app",
            messagingSenderId: "887624550714",
            appId: "1:887624550714:web:b7c0ade75937c359fe6803",
            measurementId: "G-ZFSSKH60E9"));
  } else {
    await Firebase.initializeApp();
  }
}
