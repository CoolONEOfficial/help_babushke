import 'package:cloud_firestore/cloud_firestore.dart';
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
          options: GoogleMapOptions(
            cameraPosition: CameraPosition(
              target: LatLng(56.328619, 44.002833),
              zoom: 17.0,
              tilt: 30.0,
            ),
          ),
        ),
//        RaisedButton(
//          child: const Text('Go to London'),
//          onPressed: mapController == null
//              ? null
//              : () {
//                  mapController.animateCamera(CameraUpdate.newCameraPosition(
//                    const CameraPosition(
//                      bearing: 270.0,
//                      target: LatLng(56.328619, 44.002833),
//                      tilt: 30.0,
//                      zoom: 17.0,
//                    ),
//                  ));
//                },
//        ),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    Firestore.instance.collection('tasks').snapshots().listen((snapshot) {
      for (var mDoc in snapshot.documents) {
        var mDocGeoPoint = mDoc.data["coord"] as GeoPoint;
        mapController.addMarker(MarkerOptions(
            consumeTapEvents: true,
            position: LatLng(mDocGeoPoint.latitude, mDocGeoPoint.longitude)));
      }
    });
    setState(() {
      mapController = controller;
      mapController.onMarkerTapped.add((marker) {});
    });
  }
}
