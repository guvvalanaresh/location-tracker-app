import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapTestScreen extends StatefulWidget {
  const GoogleMapTestScreen({super.key});

  @override
  _GoogleMapTestScreenState createState() => _GoogleMapTestScreenState();
}

class _GoogleMapTestScreenState extends State<GoogleMapTestScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(17.3850, 78.4867); // Hyderabad example

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Map Test')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
