import '/flutter_flow/custom_functions.dart' as custom_functions;

Future<double> calculateRealTimeKindex(
  double currentScore,
  int newStarRating,
) async {
  return custom_functions.updateKindexScore(
    currentScore,
    newStarRating,
  );
}
