import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:help_babushke/auth.dart';
import 'package:help_babushke/models.dart';

bool isLoggedIn;

const ROUTE_MAP = "/";
const ROUTE_ABOUT = "/about";
const ROUTE_AUTH = "/auth";

const ROUTE_HOME = ROUTE_MAP;

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
        ROUTE_HOME: (context) => HomeScreen(),
        ROUTE_AUTH: (context) => AuthScreen(),
      },
    ),
  );
}

class HomeScreen extends StatefulWidget {
  LatLng initCoord = new LatLng(56.328619, 44.002833);

  @override
  State createState() => HomeScreenState();
}

enum HomeScreenType {
  MAP,
  LIST,
}

class HomeScreenState extends State<HomeScreen> {
  GoogleMapController mapController;

  HomeScreenType type = HomeScreenType.MAP;
  final Map<String, TaskModel> tasks = Map<String, TaskModel>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Хедер хуедр'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Помочь даше путешествиннице найти карту'),
              onTap: () {
                setState(() => type = HomeScreenType.MAP);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Открыть гл.лист'),
              onTap: () {
                setState(() => type = HomeScreenType.LIST);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
          title: Text(type == HomeScreenType.MAP
              ? 'Всем картам карта'
              : "Всем спискам списк")),
      body: type == HomeScreenType.MAP
          ? GoogleMap(
              onMapCreated: _onMapCreated,
              options: GoogleMapOptions(
                cameraPosition: CameraPosition(
                  target: widget.initCoord,
                  zoom: 17.0,
                  tilt: 30.0,
                ),
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        type = HomeScreenType.MAP;
                      });
                      final coord = tasks.values
                          .elementAt(index)
                          .vars[TaskNames.coord.index] as GeoPoint;
                      widget.initCoord =
                          LatLng(coord.latitude, coord.longitude);
                    },
                    child: Card(
                      child: Container(
                        height: 100,
                        child: Center(
                          child: Text(
                            tasks.values
                                .elementAt(index)
                                .vars[TaskNames.name.index] as String,
                            style: Theme.of(context).textTheme.title,
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
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
            "Важность: ${markerTask.vars[TaskNames.level.index]}",
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
