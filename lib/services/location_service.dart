import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  LatLng? _lastSavedPosition; // <-- Prevent duplicate writes

  /// Live position stream with your custom config
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // real device works, emulator ignores
      ),
    );
  }

  /// Save a single location point to Firestore
  Future<void> saveLocation(Position position, String userId) async {
    String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('location_history')
          .doc(dateKey)
          .collection('points')
          .add({
        "lat": position.latitude,
        "long": position.longitude,
        "timestamp": Timestamp.now(),
        "hour": DateTime.now().hour,
      });

      print("🔥 SAVED TO FIRESTORE");
    } catch (e) {
      print("❌ FIRESTORE ERROR: $e");
    }
  }

  /// Start real-time tracking using the custom stream
  void startTracking(String userId) {
    getPositionStream().listen((Position position) {
      LatLng current = LatLng(position.latitude, position.longitude);

      // Prevent saving same location repeatedly
      if (_lastSavedPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastSavedPosition!.latitude,
          _lastSavedPosition!.longitude,
          current.latitude,
          current.longitude,
        );

        if (distance < 8) { // ignore small changes
          print("⚠️ Skipped saving — movement < 8m");
          return;
        }
      }

      print("📍 POSITION: ${current.latitude}, ${current.longitude}");

      saveLocation(position, userId);

      _lastSavedPosition = current;
    });
  }

  /// Fetch location history for any specific date + hour
  Future<List<LatLng>> getLocationsFor(
      DateTime date, int hour, String userId) async {
    String dateKey = DateFormat('yyyy-MM-dd').format(date);

    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('location_history')
          .doc(dateKey)
          .collection('points')
          .where("hour", isEqualTo: hour)
          .orderBy("timestamp")
          .get();

      return snapshot.docs.map((doc) {
        return LatLng(doc["lat"], doc["long"]);
      }).toList();
    } catch (e) {
      print("❌ ERROR READING HISTORY: $e");
      return [];
    }
  }
}
