import 'package:flutter/material.dart';
import 'app_constants.dart';
import '/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _userPoints = prefs.getInt('ff_userPoints') ?? _userPoints;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _businessname = '';
  String get businessname => _businessname;
  set businessname(String value) {
    _businessname = value;
  }

  String _category = '';
  String get category => _category;
  set category(String value) {
    _category = value;
  }

  LatLng? _location = LatLng(29.5062414, -98.30683979999999);
  LatLng? get location => _location;
  set location(LatLng? value) {
    _location = value;
  }

  String _address = '';
  String get address => _address;
  set address(String value) {
    _address = value;
  }

  String _status = '';
  String get status => _status;
  set status(String value) {
    _status = value;
  }

  bool _isfeatured = false;
  bool get isfeatured => _isfeatured;
  set isfeatured(bool value) {
    _isfeatured = value;
  }

  String _city = '';
  String get city => _city;
  set city(String value) {
    _city = value;
  }

  String _zipcode = '';
  String get zipcode => _zipcode;
  set zipcode(String value) {
    _zipcode = value;
  }

  int _userPoints = 785;
  int get userPoints => _userPoints;
  set userPoints(int value) {
    _userPoints = value;
    prefs.setInt('ff_userPoints', value);
  }

  String _tickersymbol = '';
  String get tickersymbol => _tickersymbol;
  set tickersymbol(String value) {
    _tickersymbol = value;
  }

  double _kindexscore = FFAppConstants.kindexDefaultScore;
  double get kindexscore => _kindexscore;
  set kindexscore(double value) {
    _kindexscore = value
        .clamp(
          FFAppConstants.kindexMinimumScore,
          FFAppConstants.kindexMaximumScore,
        )
        .toDouble();
  }

  String _phone = '';
  String get phone => _phone;
  set phone(String value) {
    _phone = value;
  }

  String _website = '';
  String get website => _website;
  set website(String value) {
    _website = value;
  }

  String _about = '';
  String get about => _about;
  set about(String value) {
    _about = value;
  }

  List<dynamic> _businessReviews = [];
  List<dynamic> get businessReviews => _businessReviews;
  set businessReviews(List<dynamic> value) {
    _businessReviews = value;
  }

  void addToBusinessReviews(dynamic value) {
    businessReviews.add(value);
  }

  void removeFromBusinessReviews(dynamic value) {
    businessReviews.remove(value);
  }

  void removeAtIndexFromBusinessReviews(int index) {
    businessReviews.removeAt(index);
  }

  void updateBusinessReviewsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    businessReviews[index] = updateFn(_businessReviews[index]);
  }

  void insertAtIndexInBusinessReviews(int index, dynamic value) {
    businessReviews.insert(index, value);
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
