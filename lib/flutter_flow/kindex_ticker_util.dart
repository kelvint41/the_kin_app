import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Pure ticker-string generation plus the `ticker_registry` reservation
/// write, shared by KinServices (business/customer ticker orchestration)
/// and backend.dart's maybeCreateUser (automatic ticker assignment at
/// signup). Deliberately has no dependency on backend.dart or auth_util.dart
/// so both of those can import it without a circular import.
class KindexTickerUtil {
  KindexTickerUtil._();

  static final _random = Random();
  static const _tickerChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const tickerLength = 5;

  // Filler words stripped from a name before deriving a semantic ticker -
  // matched as whole tokens (case-insensitive), not substrings, so e.g.
  // "Cole" doesn't lose its 'co'.
  static const _fillerWords = ['LLC', 'INC', 'CO', 'THE'];

  /// Uppercases and strips [raw] down to alphanumeric characters, returning
  /// null if the result isn't exactly [tickerLength] characters.
  static String? sanitize(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    return cleaned.length == tickerLength ? cleaned : null;
  }

  static String randomCandidate() => List.generate(
        tickerLength,
        (_) => _tickerChars[_random.nextInt(_tickerChars.length)],
      ).join();

  /// Derives a semantic ticker candidate from [name] (e.g. 'Rollin Smoke
  /// BBQ' -> 'ROLLI'), or null if fewer than [tickerLength] alphanumeric
  /// characters remain once filler words ('LLC', 'Inc', 'Co', 'The') and
  /// punctuation/spaces are stripped.
  static String? semanticCandidate(String name) {
    final words = name
        .toUpperCase()
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((w) => w.isNotEmpty && !_fillerWords.contains(w));
    final cleaned = words.join();
    return cleaned.length >= tickerLength
        ? cleaned.substring(0, tickerLength)
        : null;
  }

  /// Atomically reserves [ticker] in `ticker_registry` for [ownerRef].
  /// Returns true if the ticker was free and is now reserved, false if it
  /// was already taken (or the write otherwise failed). Doc ID is the
  /// ticker itself, so a write to a free ticker is a Firestore 'create'
  /// (allowed by rules) while a write to an already-taken one is an
  /// 'update' against an existing doc ('allow update: if false' blocks
  /// it) - this stays race-safe without a transaction.
  static Future<bool> reserve(String ticker, DocumentReference ownerRef) async {
    try {
      await FirebaseFirestore.instance
          .collection('ticker_registry')
          .doc(ticker)
          .set({
        'owner_ref': ownerRef,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
