import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:help_babushke/auth.dart';
import 'package:help_babushke/models.dart';

bool isLoggedIn;

const ROUTE_AUTH = "/auth";
const ROUTE_HOME = "/";

void main() async {
  final user = await FirebaseAuth.instance.currentUser();
  runApp(
    MaterialApp(
      initialRoute: user != null &&
              (await Firestore.instance
                      .collection("users")
                      .document(user.uid)
                      .get()) !=
                  null
          ? ROUTE_HOME
          : ROUTE_AUTH,
      routes: {
        ROUTE_HOME: (context) => Scaffold(
              appBar: AppBar(title: const Text('Help volunteers')),
              body: MapsDemo(),
            ),
        ROUTE_AUTH: (context) => AuthScreen(),
      },
    ),
  );
}

class MapsDemo extends StatefulWidget {
  @override
  State createState() => MapsDemoState();
}

class MapsDemoState extends State<MapsDemo> {
  GoogleMapController mapController;

  final Map<String, TaskModel> tasks = Map<String, TaskModel>();

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
      ],
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    TaskModel markerTask,
  ) =>
      Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Text(
            markerTask.vars[TaskNames.name.index],
            style: Theme.of(context).textTheme.title,
          ),
          Text(
            "Level: ${markerTask.vars[TaskNames.level.index]}",
            style: Theme.of(context).textTheme.title,
          ),
        ],
      );

  void _onMapCreated(GoogleMapController controller) {
    Firestore.instance.collection('tasks').snapshots().listen(
      (snapshot) async {
        for (var mDoc in snapshot.documents) {
          final mTask = TaskModel(mDoc);
          var mDocGeoPoint = mTask.vars[TaskNames.coord.index] as GeoPoint;
          final mMarker = await mapController.addMarker(
            MarkerOptions(
              consumeTapEvents: true,
              position: LatLng(
                mDocGeoPoint.latitude,
                mDocGeoPoint.longitude,
              ),
            ),
          );

          tasks[mMarker.id] = mTask;
        }
      },
    );
    setState(
      () {
        mapController = controller;
        mapController.onMarkerTapped.add(
          (marker) {
            final markerTask = tasks[marker.id];
            final coord = markerTask.vars[TaskNames.coord.index] as GeoPoint;
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(coord.latitude, coord.longitude),
                  tilt: 30.0,
                  zoom: 18.0,
                ),
              ),
            );
            showBottomSheet<void>(
              context: context,
              builder: (BuildContext context) => _buildBottomSheet(
                    context,
                    markerTask,
                  ),
            );
          },
        );
      },
    );
  }
}
