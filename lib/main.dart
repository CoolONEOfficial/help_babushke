import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gplacespicker/gplacespicker.dart';
import 'package:help_babushke/auth.dart';
import 'package:help_babushke/models.dart';
import 'package:intl/intl.dart';

bool isLoggedIn;

const ROUTE_MAP = "/";
const ROUTE_ABOUT = "/about";
const ROUTE_AUTH = "/auth";
const ROUTE_CREATE_EVENT = "/create_event";

const ROUTE_HOME = ROUTE_MAP;

FirebaseUser user;
UserModel userModel;

void main() async {
  user = await FirebaseAuth.instance.currentUser();
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
        ROUTE_ABOUT: (context) => AboutScreen(),
        ROUTE_CREATE_EVENT: (context) => CreateEventScreen(),
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
  REQUESTS,
}

class HomeScreenState extends State<HomeScreen> {
  GoogleMapController mapController;

  HomeScreenType type = HomeScreenType.MAP;
  final Map<String, TaskModel> tasks = Map<String, TaskModel>();

  @override
  void initState() {
    FirebaseAuth.instance.currentUser().then((user) async {
      userModel = UserModel(await Firestore.instance
          .collection("users")
          .document(user.uid)
          .get());
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidgets = <Widget>[
      UserAccountsDrawerHeader(
        accountName: Text(user?.displayName ?? ""),
        accountEmail: Text(user?.email ?? ""),
        currentAccountPicture: new CircleAvatar(
            backgroundColor: Colors.brown,
            child: Text(user?.displayName
                    ?.split(' ')
                    ?.expand((m) => <String>[m[0]])
                    ?.join() ??
                "")),
      ),
      ListTile(
        title: Text('Помочь даше путешествиннице найти карту'),
        onTap: () {
          setState(() => type = HomeScreenType.MAP);
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: Text('Открыть список'),
        onTap: () {
          setState(() => type = HomeScreenType.LIST);
          Navigator.pop(context);
        },
      ),
    ];

    if (userModel != null && userModel.vars[UserNames.admin.index]) {
      drawerWidgets.add(Divider());
      drawerWidgets
        ..add(
          ListTile(
            title: Text('Новобранцы'),
            onTap: () {
              setState(() => type = HomeScreenType.REQUESTS);
              Navigator.pop(context);
            },
          ),
        )
        ..add(
          ListTile(
            title: Text('Добавить task'),
            onTap: () {
              Navigator.popAndPushNamed(context, ROUTE_CREATE_EVENT);
            },
          ),
        );
    }

    drawerWidgets.add(Divider());
    drawerWidgets.add(
      ListTile(
        title: Text('О приложении'),
        onTap: () {
          Navigator.popAndPushNamed(context, ROUTE_ABOUT);
        },
      ),
    );

    Widget body;
    String title;

    switch (type) {
      case HomeScreenType.MAP:
        title = "Карта";
        body = GoogleMap(
          onMapCreated: _onMapCreated,
          options: GoogleMapOptions(
            cameraPosition: CameraPosition(
              target: widget.initCoord,
              zoom: 17.0,
              tilt: 30.0,
            ),
          ),
        );
        break;
      case HomeScreenType.LIST:
        title = "Список";
        body = ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  setState(() {
                    type = HomeScreenType.MAP;
                  });
                  final coord = tasks.values
                      .elementAt(index)
                      .vars[TaskNames.coord.index] as GeoPoint;
                  widget.initCoord = LatLng(coord.latitude, coord.longitude);
                },
                child: Card(
                  child: Container(
                    height: 100,
                    child: Center(
                      child: Text(
                        tasks.values.elementAt(index).vars[TaskNames.name.index]
                            as String,
                        style: Theme.of(context).textTheme.title,
                      ),
                    ),
                  ),
                ),
              ),
        );
        break;
      case HomeScreenType.REQUESTS:
        title = "Новобранцы";
        body = StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection("organisationRequests")
              // .where('orgId', isEqualTo: userModel.vars[UserNames.orgId.index])
              .getDocuments()
              .asStream(),
          builder: (context, snapshotReq) => ListView.builder(
                itemCount: snapshotReq.data?.documents?.length ?? 0,
                itemBuilder: (context, index) => StreamBuilder<QuerySnapshot>(
                      stream: Firestore.instance
                          .collection("users")
                          .getDocuments()
                          .asStream(),
                      builder: (context, snapshotUsers) => GestureDetector(
                            onTap: () async {
                              for (final mDeleteDoc in (await Firestore.instance
                                      .collection("organisationRequests")
                                      .where("userId", isEqualTo: user.uid)
                                      .getDocuments())
                                  .documents) {
                                await mDeleteDoc.reference.delete();
                              }
                              setState(() {});
                            },
                            child: Card(
                              child: Container(
                                height: 100,
                                child: Center(
                                  child: Text(
                                    snapshotUsers.data != null
                                        ? UserModel(
                                            snapshotUsers.data?.documents
                                                ?.firstWhere(
                                              (mDoc) =>
                                                  mDoc.documentID ==
                                                  OrgRequestModel(
                                                    snapshotReq.data.documents
                                                        .elementAt(index),
                                                  ).vars[OrgRequestNames
                                                      .userId.index],
                                            ),
                                          ).vars[UserNames.name.index] as String
                                        : "",
                                    style: Theme.of(context).textTheme.title,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
              ),
        );
        break;
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: drawerWidgets,
        ),
      ),
      appBar: AppBar(
        title: Text(title),
      ),
      body: body,
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

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("ХУЕВО ТУТ"),
        ),
        body: Container(
          child: Center(
            child: Text("Мне так хуево в KFC сидеть, все бухают, а я нет(("),
          ),
        ),
      );
}

class CreateEventScreen extends StatefulWidget {
  @override
  CreateEventScreenState createState() {
    return CreateEventScreenState();
  }
}

class CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  double level = 5;
  Map<String, dynamic> place;
  DateTime start, finish;
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Добаление таска каска"),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                style: Theme.of(context).textTheme.title,
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Название",
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Ты ничего не забыл?';
                  }
                },
              ),
              TextFormField(
                style: Theme.of(context).textTheme.subtitle,
                controller: descController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Описание",
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Ты ничего не забыл????';
                  }
                },
              ),
              Container(
                padding: EdgeInsets.all(4),
                child: Column(
                  children: <Widget>[
                    Text(
                      "Важность:",
                      style: Theme.of(context).textTheme.title,
                    ),
                    Slider(
                      onChanged: (double value) {
                        level = value;
                        setState(() {});
                      },
                      value: level,
                      divisions: 10,
                      max: 10.0,
                      min: 0.0,
                      label: '${level.round()}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(4),
                child: Column(
                  children: <Widget>[
                    Text(
                      "Место:",
                      style: Theme.of(context).textTheme.title,
                    ),
                    Center(
                      child: Column(
                        children: <Widget>[
                          FlatButton(
                              onPressed: () async {
                                place = jsonDecode(
                                    await Gplacespicker.openPlacePicker());
                                setState(() {});
                              },
                              child: Text(place == null
                                  ? "Выбрать..."
                                  : "Выбрано: ${place["place"]}")),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              DateTimePickerFormField(
                decoration: InputDecoration(labelText: 'Начало'),
                onChanged: (date) => setState(() => start = date),
                format: DateFormat.Hm(),
              ),
              DateTimePickerFormField(
                decoration: InputDecoration(labelText: 'Конец'),
                onChanged: (date) => setState(() => finish = date),
                format: DateFormat.Hm(),
              ),
              Center(
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      if (place == null)
                        SnackBar(content: Text('Не выбрана дата'));
                      else {
                        _scaffoldKey.currentState
                            .showSnackBar(SnackBar(content: Text('Поехали')));

                        final coord = GeoPoint(
                          place['latitude'],
                          place['longitude'],
                        );
                        await Firestore.instance.collection('tasks').add(
                          {
                            'adminId': user.uid,
                            'name': nameController.value.text,
                            'description': descController.value.text,
                            'start': Timestamp.fromDate(start),
                            'finish': Timestamp.fromDate(finish),
                            'level': level,
                            'coord': coord,
                          },
                        );

                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text('Ага...'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
