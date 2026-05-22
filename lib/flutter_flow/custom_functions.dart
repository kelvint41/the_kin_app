import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/models/kin_business_profile.dart';

int updateKindexScore(
  double? currentScore,
  int? reviewRatings,
) {
  if (reviewRatings == null) {
    return (currentScore ?? 100.0).round().clamp(100, 750);
  }

  return KinBusinessProfile.applyReviewToKindexScore(
    currentScore: currentScore ?? 100.0,
    reviewRating: reviewRatings,
  );
}
