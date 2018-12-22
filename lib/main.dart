import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Google Maps demo')),
      body: MapsDemo(),
    ),
  ));
}

class MapsDemo extends StatefulWidget {
  @override
  State createState() => MapsDemoState();
}

class MapsDemoState extends State<MapsDemo> {
  GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GoogleMap(
          onMapCreated: _onMapCreated,
        ),
        RaisedButton(
          child: const Text('Go to London'),
          onPressed: mapController == null
              ? null
              : () {
                  mapController.animateCamera(CameraUpdate.newCameraPosition(
                    const CameraPosition(
                      bearing: 270.0,
                      target: LatLng(51.5160895, -0.1294527),
                      tilt: 30.0,
                      zoom: 17.0,
                    ),
                  ));
                },
        ),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }
}
