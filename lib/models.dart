import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DbVar<T> {
  final T variable;

  DbVar._(this.variable);

  factory DbVar(
    DocumentSnapshot snapshot,
    bool required,
    String key,
  ) {
    var data = snapshot.data[key];

    if (!(data is T)) {
      debugPrint("Data $key => '$data' is not a ${T.toString()}!!");
      data = null;
    }

    if (required && data == null) debugPrint("$key required and not found!!");

    return DbVar._(data);
  }
}

enum TaskNames {
  name,
  adminId,
  level,
  coord,
}

class TaskModel {
  factory TaskModel(DocumentSnapshot snapshot) => TaskModel._(
        List.generate(
          TaskNames.values.length,
          (index) {
            switch (TaskNames.values[index]) {
              case TaskNames.adminId:
                return DbVar<String>(snapshot, true, "adminId").variable;
              case TaskNames.name:
                return DbVar<String>(snapshot, true, "name").variable;
              case TaskNames.coord:
                return DbVar<GeoPoint>(snapshot, true, "coord").variable;
              case TaskNames.level:
                return DbVar<int>(snapshot, true, "level").variable;
            }
          },
        ),
      );

  TaskModel._(this.vars);

  final List vars;
}

enum OrganisationNames {
  name,
  coord,
  phoneNumber,
}

class OrganisationModel {
  factory OrganisationModel(DocumentSnapshot snapshot) => OrganisationModel._(
        List.generate(
          OrganisationNames.values.length,
          (index) {
            switch (OrganisationNames.values[index]) {
              case OrganisationNames.phoneNumber:
                return DbVar<String>(snapshot, true, "phoneNumber").variable;
              case OrganisationNames.name:
                return DbVar<String>(snapshot, true, "name").variable;
              case OrganisationNames.coord:
                return DbVar<GeoPoint>(snapshot, true, "coord").variable;
            }
          },
        ),
      );

  OrganisationModel._(this.vars);

  final List vars;
}
