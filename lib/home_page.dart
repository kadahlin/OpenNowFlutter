import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'distance_dialog.dart';
import 'home_page_body.dart';
import 'open_now_redux.dart';

///Container for app, includes the app bar and the fab
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<RestaurantResult, ActionCallback>(converter: (store) {
      return (action) => store.dispatch(action);
    }, builder: (context, callback) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Open Now"),
          actions: <Widget>[
            PopupMenuButton<SortingMethod>(
              onSelected: (method) => callback(SortRestaurantAction(method)),
              itemBuilder: (context) {
                return [
                  PopupMenuItem<SortingMethod>(
                    value: SortingMethod.alphabetical,
                    child: Text("Alphabetical"),
                  ),
                  PopupMenuItem<SortingMethod>(
                    value: SortingMethod.distance,
                    child: Text("Distance"),
                  ),
                ];
              },
            )
          ],
        ),
        body: HomePageBody(storeCallback: callback,),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final status = await SimplePermissions.requestPermission(Permission.WhenInUseLocation);
            if (status == PermissionStatus.authorized) {
              DistanceDialog.showDistanceDialog(context);
            } else {
              callback(UpdatePermissionAction(status));
            }
          },
          child: Icon(Icons.restaurant),
        ),
      );
    });
  }
}
