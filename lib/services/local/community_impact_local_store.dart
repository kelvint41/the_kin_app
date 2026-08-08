import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/businesses_record.dart';
import '/backend/schema/spend_logs_record.dart';
import '/flutter_flow/flutter_flow_util.dart' show getCurrentTimestamp;

/// One "Log a Visit / Spend" entry in the Community Impact tracker.
///
/// [id] is the Firestore doc id once synced (see
/// [CommunityImpactLocalStore]), or a client-generated placeholder for the
/// brief window between an optimistic local add and Firestore assigning
/// the real one.
class SpendLogEntry {
  SpendLogEntry({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.amount,
    required this.date,
    this.businessCity = '',
    this.businessCategory = '',
    this.note = '',
  });

  final String id;
  final String businessId;
  final String businessName;
  final double amount;
  final DateTime date;
  final String note;

  /// Denormalized off the matched business at log time - empty for a
  /// free-text entry with no match. Feeds community_impact_stats'
  /// by-city/by-category breakdown; see spend_log_aggregate.js.
  final String businessCity;
  final String businessCategory;

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'businessName': businessName,
        'businessCity': businessCity,
        'businessCategory': businessCategory,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory SpendLogEntry.fromJson(Map<String, dynamic> json) => SpendLogEntry(
        id: json['id'] as String,
        businessId: json['businessId'] as String? ?? '',
        businessName: json['businessName'] as String? ?? 'Local Business',
        businessCity: json['businessCity'] as String? ?? '',
        businessCategory: json['businessCategory'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
        note: json['note'] as String? ?? '',
      );

  factory SpendLogEntry.fromRecord(SpendLogsRecord r) => SpendLogEntry(
        id: r.reference.id,
        businessId: r.businessRef?.id ?? '',
        businessName: r.businessName,
        businessCity: r.businessCity,
        businessCategory: r.businessCategory,
        amount: r.amount,
        date: r.spentAt ?? r.createdAt ?? DateTime.now(),
        note: r.note,
      );
}

/// A single Community Impact achievement tile. [unlocked] is computed live
/// from the current entry list every time [CommunityImpactLocalStore.badges]
/// is read, so it's never stored or allowed to go stale.
class ImpactBadge {
  const ImpactBadge({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final bool unlocked;
}

/// "Community Impact & Spend Tracker" store - Firestore-backed, with a
/// SharedPreferences cache for instant cold-start rendering.
///
/// Firestore (`spend_logs`) is the source of truth and is strictly
/// owner-only in firestore.rules - see that file's comment on the
/// collection for why: what a customer has spent is never readable by
/// anyone else, not another customer, not the KINDEX leaderboard, not
/// admin tooling. This store only ever reads/writes the signed-in user's
/// own entries, which is all the rules permit regardless.
///
/// Every metric below (total spend, unique businesses, streak, badges) is
/// derived from the entry list on every read rather than stored anywhere,
/// so there is no separate aggregate that could drift out of sync with the
/// underlying entries.
class CommunityImpactLocalStore extends ChangeNotifier {
  CommunityImpactLocalStore._();
  static final CommunityImpactLocalStore instance =
      CommunityImpactLocalStore._();

  static const _prefsKey = 'kin_spend_log_entries';

  SharedPreferences? _prefs;
  List<SpendLogEntry> _entries = [];
  bool _loaded = false;

  StreamSubscription<QuerySnapshot>? _subscription;
  String? _boundUserId;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (!_loaded) {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getStringList(_prefsKey) ?? const <String>[];
      _entries = raw
          .map((s) =>
              SpendLogEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
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

    // One-time migration, same reasoning as FavoritesLocalStore: entries
    // logged before this collection existed (or while offline) get pushed
    // up rather than silently dropped once the live listener's first
    // snapshot replaces the local list. Matched by (businessName, amount,
    // date) rather than id, since local-only entries never had a real
    // Firestore id to match on.
    final toMigrate = _entries.where((e) => e.id.length < 20).toList();

    _subscription = SpendLogsRecord.collection
        .where('user_ref', isEqualTo: userRef)
        .orderBy('spent_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      final remote = snapshot.docs
          .map((doc) => SpendLogEntry.fromRecord(SpendLogsRecord.fromSnapshot(doc)))
          .toList();

      if (toMigrate.isNotEmpty) {
        final remoteKeys = remote
            .map((e) => '${e.businessName}|${e.amount}|${e.date.toIso8601String()}')
            .toSet();
        final missing = toMigrate.where((e) => !remoteKeys.contains(
            '${e.businessName}|${e.amount}|${e.date.toIso8601String()}'));
        for (final entry in missing) {
          _writeEntry(userRef, entry);
        }
        toMigrate.clear();
        _entries = [...remote, ...missing]
          ..sort((a, b) => b.date.compareTo(a.date));
      } else {
        _entries = remote;
      }
      _persistCache();
      notifyListeners();
    });
  }

  /// Most recent first.
  List<SpendLogEntry> get entries => List.unmodifiable(_entries);

  double get totalSpend => _entries.fold(0.0, (sum, e) => sum + e.amount);

  int get uniqueBusinessCount => _entries
      .map((e) => e.businessId.isNotEmpty
          ? 'id:${e.businessId}'
          : 'name:${e.businessName.trim().toLowerCase()}')
      .toSet()
      .length;

  /// Consecutive calendar months (counting back from the current month)
  /// that have at least one logged visit/spend.
  int get currentStreakMonths {
    if (_entries.isEmpty) return 0;
    final months =
        _entries.map((e) => DateTime(e.date.year, e.date.month)).toSet();
    var cursor = DateTime(DateTime.now().year, DateTime.now().month);
    var streak = 0;
    while (months.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month - 1);
    }
    return streak;
  }

  List<ImpactBadge> get badges => [
        ImpactBadge(
          id: 'first_visit',
          label: 'First Steps',
          description: 'Logged your first visit or spend',
          icon: Icons.emoji_events_rounded,
          unlocked: _entries.isNotEmpty,
        ),
        ImpactBadge(
          id: 'five_businesses',
          label: 'Neighborhood Regular',
          description: 'Supported 5 unique Black-owned businesses',
          icon: Icons.storefront_rounded,
          unlocked: uniqueBusinessCount >= 5,
        ),
        ImpactBadge(
          id: 'streak_3',
          label: 'Streak Keeper',
          description: '3-month support streak',
          icon: Icons.local_fire_department_rounded,
          unlocked: currentStreakMonths >= 3,
        ),
        ImpactBadge(
          id: 'spend_500',
          label: 'Community Investor',
          description: r'Logged $500+ in local spend',
          icon: Icons.volunteer_activism_rounded,
          unlocked: totalSpend >= 500,
        ),
        ImpactBadge(
          id: 'ten_businesses',
          label: 'KIN Champion',
          description: 'Supported 10 unique Black-owned businesses',
          icon: Icons.workspace_premium_rounded,
          unlocked: uniqueBusinessCount >= 10,
        ),
      ];

  Future<void> addEntry({
    required String businessName,
    required double amount,
    required DateTime date,
    String businessId = '',
    String businessCity = '',
    String businessCategory = '',
    String note = '',
  }) async {
    await ensureLoaded();
    final userRef = currentUserReference;
    if (userRef == null) return; // Nothing to persist against signed out.

    // Optimistic add with a short placeholder id, replaced by the real
    // Firestore id when the live listener's next snapshot arrives.
    final optimistic = SpendLogEntry(
      id: 'pending_${DateTime.now().microsecondsSinceEpoch}',
      businessId: businessId,
      businessName: businessName.trim(),
      businessCity: businessCity.trim(),
      businessCategory: businessCategory.trim(),
      amount: amount,
      date: date,
      note: note.trim(),
    );
    _entries = [optimistic, ..._entries];
    _persistCache();
    notifyListeners();

    try {
      await _writeEntry(userRef, optimistic);
    } catch (_) {
      _entries = _entries.where((e) => e.id != optimistic.id).toList();
      _persistCache();
      notifyListeners();
    }
  }

  Future<void> _writeEntry(DocumentReference userRef, SpendLogEntry entry) =>
      SpendLogsRecord.collection.add(createSpendLogsRecordData(
        userRef: userRef,
        businessRef: entry.businessId.isEmpty
            ? null
            : BusinessesRecord.collection.doc(entry.businessId),
        businessName: entry.businessName,
        businessCity:
            entry.businessCity.isEmpty ? null : entry.businessCity,
        businessCategory:
            entry.businessCategory.isEmpty ? null : entry.businessCategory,
        amount: entry.amount,
        spentAt: entry.date,
        note: entry.note,
        createdAt: getCurrentTimestamp,
      ));

  Future<void> removeEntry(String id) async {
    await ensureLoaded();
    final removed = _entries.where((e) => e.id == id).toList();
    _entries = _entries.where((e) => e.id != id).toList();
    _persistCache();
    notifyListeners();

    // A synced entry's id is its real Firestore doc id; an optimistic one
    // (still pending its first snapshot) has no doc to delete yet.
    if (id.startsWith('pending_')) return;
    try {
      await SpendLogsRecord.collection.doc(id).delete();
    } catch (_) {
      if (removed.isNotEmpty) {
        _entries = [...removed, ..._entries]
          ..sort((a, b) => b.date.compareTo(a.date));
        _persistCache();
        notifyListeners();
      }
    }
  }

  Future<void> _persistCache() async {
    final raw = _entries.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs?.setStringList(_prefsKey, raw);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
