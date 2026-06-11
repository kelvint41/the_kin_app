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
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/app_constants.dart';

double updateKindexScore(
  double? currentScore,
  int? reviewRatings,
) {
  double scoreChange = 0.0;
  final score = (currentScore ?? FFAppConstants.kindexDefaultScore).clamp(
    FFAppConstants.kindexMinimumScore,
    FFAppConstants.kindexMaximumScore,
  );

  if (reviewRatings == null) return score.toDouble();

  switch (reviewRatings) {
    case 5:
      scoreChange = 15.0;
      break;
    case 4:
      scoreChange = 5.0;
      break;
    case 1:
      scoreChange = -15.0;
      break;
    case 2:
      scoreChange = -5.0;
      break;
    default:
      scoreChange = 0.0;
  }

  final newScore = score + scoreChange;
  return newScore
      .clamp(
        FFAppConstants.kindexMinimumScore,
        FFAppConstants.kindexMaximumScore,
      )
      .toDouble();
}
