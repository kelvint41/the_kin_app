// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<double> calculateRealTimeKindex(
  double currentScore,
  int newStarRating,
  String businessName,
) async {
  const double standardBaseline = 500.0;
  const double premiumBaseline = 850.0;
  const double minimumScore = 0.0;
  const double standardMaximumScore = 750.0;
  const double premiumMaximumScore = 900.0;
  const String premiumBusinessName = 'Hair Maddness LLC';

  final bool isPremiumBusiness = businessName.trim() == premiumBusinessName;

  // Determine the correct starting baseline for this business.
  final double baseline =
      isPremiumBusiness ? premiumBaseline : standardBaseline;
  // Premium's 850 baseline exceeded the old shared 750 ceiling, so it was
  // clamped away on every call — this gives each tier its own ceiling
  // instead of silently truncating the premium baseline.
  final double maximumScore =
      isPremiumBusiness ? premiumMaximumScore : standardMaximumScore;

  // Treat 0.0 as "no score set yet" and apply the baseline.
  final double score = (currentScore == 0.0)
      ? baseline
      : currentScore.clamp(minimumScore, maximumScore);

  double scoreChange;
  switch (newStarRating) {
    case 5:
      scoreChange = 15.0;
      break;
    case 4:
      scoreChange = 5.0;
      break;
    case 2:
      scoreChange = -5.0;
      break;
    case 1:
      scoreChange = -15.0;
      break;
    default:
      scoreChange = 0.0; // 3-star is neutral — no change
  }

  return (score + scoreChange).clamp(minimumScore, maximumScore);
}
