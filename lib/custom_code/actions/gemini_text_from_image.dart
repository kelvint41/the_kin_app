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

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

// Supply via --dart-define=GEMINI_API_KEY=... at build time. The key that
// used to be hardcoded here was committed to source and must be treated as
// compromised — rotate it in Google AI Studio before relying on this again.
const _kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

Future<Uint8List?> loadBytesFromUrl(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (e) {
    return null;
  }
  return null;
}

Future<String?> geminiTextFromImage(
  BuildContext context,
  String prompt,
  String? imageNetworkUrl,
  FFUploadedFile? uploadImageBytes,
) async {
  // Production-safe guard: prevent null pointer crash
  if ((imageNetworkUrl == null || imageNetworkUrl.isEmpty) &&
      uploadImageBytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'No image provided. Please supply a URL or upload an image.')),
    );
    return null;
  }

  final model =
      GenerativeModel(model: 'gemini-1.5-flash', apiKey: _kGeminiApiKey);

  Uint8List? imageBytes;
  if (uploadImageBytes != null) {
    imageBytes = uploadImageBytes.bytes;
  } else {
    imageBytes = await loadBytesFromUrl(imageNetworkUrl!);
  }

  if (imageBytes == null || imageBytes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Failed to load image. Please check the URL or try uploading directly.')),
    );
    return null;
  }

  final content = [
    Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageBytes),
    ])
  ];

  try {
    final response = await model.generateContent(content);
    return response.text;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
    return null;
  }
}
