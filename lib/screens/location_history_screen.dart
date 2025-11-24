import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  LocationHistoryScreenState createState() => LocationHistoryScreenState();
}

class LocationHistoryScreenState extends State<LocationHistoryScreen> {
  late GoogleMapController mapController;
  bool _mapReady = false;

  // Map initial position (Hyderabad as default)
  final LatLng _center = const LatLng(17.3850, 78.4867);

  int selectedHour = DateTime.now().hour;
  DateTime selectedDate = DateTime.now();

  // For history view
  Set<Marker> _historyMarkers = {};
  Set<Polyline> _historyPolylines = {};

  // For playback
  List<LatLng> _currentPath = [];
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    log("INIT STATE CALLED");
    _requestPermissions();
    _startLocationTracking();
  }

  void _requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    log("Permission: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      log("After request: $permission");
    }

    if (permission == LocationPermission.deniedForever) {
      log("Permission denied forever");
      // You can show a dialog asking user to open app settings
    }
  }

  void _startLocationTracking() {
    log("STARTING LOCATION TRACKING...");
    // TODO: replace "testUser" with actual user id from auth
    LocationService().startTracking("testUser");
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _mapReady = true;
  }

  /// Date picker
  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });

      // Reload history when date changes
      _fetchHistoryForSelection();
    }
  }

  /// Fetch path for the current selected date + hour
  Future<void> _fetchHistoryForSelection() async {
    log("📥 Fetching history for $selectedDate at hour $selectedHour");

    final locations = await LocationService()
        .getLocationsFor(selectedDate, selectedHour, "testUser");

    log("📌 POINTS LOADED: ${locations.length}");

    if (!mounted) return;

    if (locations.isEmpty) {
      setState(() {
        _historyMarkers.clear();
        _historyPolylines.clear();
        _currentPath = [];
        _isPlaying = false;
      });
      log("❌ No data found for this hour");
      return;
    }

    _currentPath = locations; // save for playback

    // Create markers for first and last point
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: locations.first,
        infoWindow: const InfoWindow(title: "Start"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      if (locations.length > 1)
        Marker(
          markerId: const MarkerId('end'),
          position: locations.last,
          infoWindow: const InfoWindow(title: "End"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };

    // Single polyline of the path
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: locations,
      width: 4,
      color: Colors.blue,
    );

    setState(() {
      _historyMarkers = markers;
      _historyPolylines = {polyline};
    });

    // Zoom map to fit the route
    if (_mapReady && locations.length > 1) {
      final bounds = _boundsFromLatLngList(locations);
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } else if (_mapReady) {
      // only one point: just move camera
      mapController.animateCamera(
        CameraUpdate.newLatLng(locations.first),
      );
    }
  }

  /// Compute LatLngBounds from list of LatLng
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  /// Animate moving marker along the current path
  Future<void> _playRoute() async {
    if (_currentPath.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough points to play this route")),
      );
      return;
    }

    if (!_mapReady) return;

    // Toggle off if already playing
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    setState(() {
      _isPlaying = true;
    });

    // We keep the polyline as is, only update the "moving" marker
    for (int i = 0; i < _currentPath.length; i++) {
      if (!_isPlaying || !_mapReady) break;

      final pos = _currentPath[i];

      final markers = <Marker>{
        // static start marker
        Marker(
          markerId: const MarkerId('start'),
          position: _currentPath.first,
          infoWindow: const InfoWindow(title: "Start"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        // static end marker
        Marker(
          markerId: const MarkerId('end'),
          position: _currentPath.last,
          infoWindow: const InfoWindow(title: "End"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
        // moving marker
        Marker(
          markerId: const MarkerId('moving'),
          position: pos,
          infoWindow: InfoWindow(title: "Step ${i + 1}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      };

      setState(() {
        _historyMarkers = markers;
      });

      // Center camera on current point
      await mapController.animateCamera(
        CameraUpdate.newLatLng(pos),
      );

      // small delay between points
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _historyMarkers,
            polylines: _historyPolylines,
          ),

          // 2. Date Picker at the top
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectDate,
                    child: const Text("Change Date"),
                  ),
                ],
              ),
            ),
          ),

          // 3. Hour slider + Play button at the bottom
          Positioned(
            bottom: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Hour: $selectedHour",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: selectedHour.toDouble(),
                    min: 0,
                    max: 23,
                    divisions: 23,
                    label: "$selectedHour",
                    onChanged: (value) {
                      setState(() {
                        selectedHour = value.toInt();
                      });

                      // reload history when hour changes
                      _fetchHistoryForSelection();
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _playRoute,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? "Stop" : "Play Route"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
