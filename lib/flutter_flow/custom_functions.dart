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
import '/backend/schema/structs/index.dart';
import '/auth/firebase_auth/auth_util.dart';

double updateKindexScore(
  int reviewRatings,
  String? businessName,
  double currentScore,
) {
  double scoreChange = 0.0;

  // Set the baseline score. If the current score is 0.0 or null, default to the 500.0 baseline.
  double score = (currentScore == 0.0) ? 500.0 : currentScore;

  switch (reviewRatings) {
    case 5:
      scoreChange = 15.0;
      break;
    case 4:
      scoreChange = 5.0;
      break;
    case 3:
      scoreChange = 0.0;
      break;
    case 2:
      scoreChange = -5.0;
      break;
    case 1:
      scoreChange = -15.0;
      break;
    default:
      scoreChange = 0.0;
  }

  double newScore = score + scoreChange;

  // Enforce strict national boundaries (Floor: 100.0, Ceiling: 800.0)
  return newScore.clamp(100.0, 800.0);
}

String? getMarkerIcon(String? category) {
  if (category == 'Restaurant') {
    return 'https://images.squarespace-cdn.com/content/v1/63ba0e8c07d353683bf1dfbf/fa24bb75-7b64-4bf8-b21a-e8d35091bfd2/Restaurant_Pin.png';
  }

  if (category == 'Salon') {
    return 'https://images.squarespace-cdn.com/content/v1/63ba0e8c07d353683bf1dfbf/ca86bb94-01fa-4f95-bdc1-840a1bfa82bb/Salon_Pin.png';
  }

  if (category == 'Lawn Care') {
    return 'https://images.squarespace-cdn.com/content/v1/63ba0e8c07d353683bf1dfbf/ea95bb12-98ea-4bf9-ac1b-f8319ba28ccb/Lawn_Pin.png';
  }

  // The absolute final safety net to keep the parser happy
  return 'https://images.squarespace-cdn.com/content/v1/63ba0e8c07d353683bf1dfbf/14603cc3-d14f-4d43-9828-b0a3bb6fa2d2/Standard_Pin.png';
}

double updateCustomerKindexScore(
  double currentScore,
  String interactionType,
  int starRating,
) {
  double runningScore = currentScore == 0.0 ? 100.0 : currentScore;

  switch (interactionType) {
    case 'delivery_click':
      runningScore += 8.0;
      break;

    case 'purchase':
      runningScore += 10.0;
      break;

    case 'review':
      if (starRating >= 3) {
        runningScore += 5.0;
      } else {
        runningScore += 1.0;
      }
      break;

    case 'social_engagement':
      runningScore += 2.0;
      break;

    case 'checkin':
      runningScore += 2.0;
      break;

    case 'decay':
      runningScore -= 5.0;
      break;
  }

  if (runningScore > 850.0) {
    runningScore = 850.0;
  }
  if (runningScore < 100.0) {
    runningScore = 100.0;
  }

  return double.parse(runningScore.toStringAsFixed(1));
}

double getProgressBarValue(
  double? score,
  double? milestoneTarget,
) {
  if (score == null) {
    return 0.0;
  }

  // Uses the passed maximum cap, or defaults to 500.0 if empty
  double target = milestoneTarget ?? 500.0;

  return (score / target).clamp(0.0, 1.0);
}

bool isBusinessOpen(
  String? openingTime,
  String? closingTime,
) {
// If either time is missing, treat the business as closed.
  if (openingTime == null ||
      closingTime == null ||
      openingTime.isEmpty ||
      closingTime.isEmpty) {
    return false;
  }

  // Converts a 12-hour string like "08:00 AM" into minutes since midnight.
  // Returns null if the string cannot be parsed.
  int? toMinutes(String raw) {
    final cleaned = raw.trim().toUpperCase();

    // Split the time portion from the AM/PM marker.
    final parts = cleaned.split(' ');
    if (parts.length != 2) return null;

    final timePart = parts[0]; // "08:00"
    final meridiem = parts[1]; // "AM" or "PM"

    final hm = timePart.split(':');
    if (hm.length != 2) return null;

    int? hour = int.tryParse(hm[0]);
    int? minute = int.tryParse(hm[1]);
    if (hour == null || minute == null) return null;
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

    // Convert to 24-hour clock.
    if (meridiem == 'PM' && hour != 12) {
      hour += 12;
    } else if (meridiem == 'AM' && hour == 12) {
      hour = 0; // 12:00 AM is midnight
    }

    return hour * 60 + minute;
  }

  final openMin = toMinutes(openingTime);
  final closeMin = toMinutes(closingTime);

  // If parsing failed on either value, fail safe to closed.
  if (openMin == null || closeMin == null) return false;

  // Current local time in minutes since midnight.
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;

  if (openMin == closeMin) {
    // Treat identical open/close as open 24 hours.
    return true;
  } else if (closeMin > openMin) {
    // Normal same-day hours, e.g. 08:00 AM to 10:00 PM.
    return nowMin >= openMin && nowMin < closeMin;
  } else {
    // Overnight hours that cross midnight, e.g. 06:00 PM to 02:00 AM.
    return nowMin >= openMin || nowMin < closeMin;
  }
}

DateTime calculateExpiration(int durationHours) {
  return DateTime.now().add(Duration(hours: durationHours));
}
