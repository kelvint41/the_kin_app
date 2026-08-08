import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/businesses_record.dart';
import '/backend/schema/saved_businesses_record.dart';
import '/flutter_flow/flutter_flow_util.dart' show getCurrentTimestamp;

/// "Favorites / Saved Places" store - Firestore-backed, with a
/// SharedPreferences cache so the heart icon and Saved Places list render
/// instantly from the last-known state instead of a blank/loading flash on
/// every app open.
///
/// Firestore is the source of truth: `saved_businesses`, one doc per
/// user+business at the deterministic id [SavedBusinessesRecord.docId], so
/// a save is a `set` and an unsave is a `delete` against a doc whose id the
/// client already knows - no query needed to check "is this saved?". A
/// live listener (started by [ensureLoaded]) keeps the cache in sync with
/// whatever wrote last, including another device.
///
/// Toggling is optimistic: the in-memory set and the on-disk cache update
/// immediately, notifying listeners before the network round-trip, then
/// roll back if the Firestore write fails. The live listener is the actual
/// reconciliation - the optimistic update is purely to keep the heart icon
/// feeling instant.
class FavoritesLocalStore extends ChangeNotifier {
  FavoritesLocalStore._();
  static final FavoritesLocalStore instance = FavoritesLocalStore._();

  static const _prefsKey = 'kin_saved_business_ids';

  SharedPreferences? _prefs;
  Set<String> _savedIds = {};
  bool _loaded = false;

  StreamSubscription<QuerySnapshot>? _subscription;
  String? _boundUserId;

  bool get isLoaded => _loaded;
  Set<String> get savedIds => Set.unmodifiable(_savedIds);
  int get count => _savedIds.length;

  /// Loads the on-disk cache immediately, then (re)binds the live Firestore
  /// listener if the signed-in user has changed since the last bind - so
  /// switching accounts on one device doesn't leak the previous account's
  /// saves.
  Future<void> ensureLoaded() async {
    if (!_loaded) {
      _prefs = await SharedPreferences.getInstance();
      _savedIds = (_prefs!.getStringList(_prefsKey) ?? const <String>[]).toSet();
      _loaded = true;
      notifyListeners();
    }
    await _bindToCurrentUser();
  }

  Future<void> _bindToCurrentUser() async {
    final userRef = currentUserReference;
    if (userRef?.id == _boundUserId) return;

    await _subscription?.cancel();
    _subscription = null;
    _boundUserId = userRef?.id;
    if (userRef == null) return; // Signed out - cache stays as last-known.

    // One-time migration: anything the cache has that Firestore doesn't
    // yet (saves made before this collection existed, or made offline)
    // gets pushed up on first bind, rather than silently vanishing the
    // moment the live listener's first snapshot overwrites the local set.
    final idsToMigrate = Set<String>.from(_savedIds);

    _subscription = SavedBusinessesRecord.collection
        .where('user_ref', isEqualTo: userRef)
        .snapshots()
        .listen((snapshot) {
      final remoteIds = snapshot.docs
          .map((doc) => SavedBusinessesRecord.fromSnapshot(doc).businessRef?.id)
          .whereType<String>()
          .toSet();

      if (idsToMigrate.isNotEmpty) {
        final missing = idsToMigrate.difference(remoteIds);
        idsToMigrate.clear();
        for (final id in missing) {
          _writeSave(userRef, id);
        }
        // The migrated ids will arrive in a follow-up snapshot; union them
        // in now so the UI doesn't flicker them off in between.
        _savedIds = remoteIds.union(missing);
      } else {
        _savedIds = remoteIds;
      }
      _persistCache();
      notifyListeners();
    });
  }

  bool isSaved(String businessId) => _savedIds.contains(businessId);

  Future<void> toggle(String businessId) async {
    if (businessId.isEmpty) return;
    await ensureLoaded();
    final userRef = currentUserReference;
    if (userRef == null) return; // Nothing to persist against signed out.

    final wasSaved = _savedIds.contains(businessId);
    // Optimistic flip - see class doc comment.
    if (wasSaved) {
      _savedIds.remove(businessId);
    } else {
      _savedIds.add(businessId);
    }
    _persistCache();
    notifyListeners();

    try {
      if (wasSaved) {
        await _docRef(userRef, businessId).delete();
      } else {
        await _writeSave(userRef, businessId);
      }
    } catch (_) {
      // Roll back the optimistic update; the next live snapshot would
      // eventually correct this too, but there's no reason to wait for it.
      if (wasSaved) {
        _savedIds.add(businessId);
      } else {
        _savedIds.remove(businessId);
      }
      _persistCache();
      notifyListeners();
    }
  }

  DocumentReference _docRef(DocumentReference userRef, String businessId) =>
      SavedBusinessesRecord.collection.doc(SavedBusinessesRecord.docId(
        userRef: userRef,
        businessRef: BusinessesRecord.collection.doc(businessId),
      ));

  Future<void> _writeSave(DocumentReference userRef, String businessId) =>
      _docRef(userRef, businessId).set(createSavedBusinessesRecordData(
        userRef: userRef,
        businessRef: BusinessesRecord.collection.doc(businessId),
        createdAt: getCurrentTimestamp,
      ));

  Future<void> _persistCache() async {
    await _prefs?.setStringList(_prefsKey, _savedIds.toList());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
