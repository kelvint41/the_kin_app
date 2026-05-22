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

int updateKindexScore(
  double? currentScore,
  int? reviewRatings,
) {
  double scoreChange = 0.0;
  double score = currentScore ?? 100.0;

  if (reviewRatings == null) return score.toInt();

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

  double newScore = score + scoreChange;
  return newScore.round().clamp(100, 750);
}
