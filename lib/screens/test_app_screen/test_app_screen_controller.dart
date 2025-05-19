import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class TestAppScreenCon {
  Map<String, dynamic> get userLatLong;

  Stream get locationStreamCon;

  Stream<List<Map<String, dynamic>>> get locationHistoryStreamCon;
}

class TestAppScreenConImpl extends TestAppScreenCon {
  Map<String, dynamic> _userLatLong = {};
  final StreamController _locationStreamCon = StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _locationHistoryStreamCon =
      StreamController.broadcast();

  @override
  Map<String, dynamic> get userLatLong => _userLatLong;

  set userLatLong(Map<String, dynamic> value) {
    _userLatLong = value;
  }

  @override
  Stream get locationStreamCon => _locationStreamCon.stream.asBroadcastStream();

  locationStream(bool value) {
    _locationStreamCon.add(value);
  }

  @override
  Stream<List<Map<String, dynamic>>> get locationHistoryStreamCon =>
      _locationHistoryStreamCon.stream.asBroadcastStream();

  locationHistoryStream(List<Map<String, dynamic>> value) {
    _locationHistoryStreamCon.add(value);
  }

  Future<void> addLocationToHistory(Map<String, dynamic> location) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getStringList('location_history') ?? [];
    existingData.add(jsonEncode(location));
    await prefs.setStringList('location_history', existingData);
    final updatedList = existingData
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .toList();
    _locationHistoryStreamCon.add(updatedList);
  }
}
