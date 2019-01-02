import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'restaurant.dart';
import 'restaurant_expansion_tile.dart';
import 'restaurant_view_model.dart';

class HomePageBody extends StatefulWidget {
  final RestaurantViewModel viewModel;

  HomePageBody({@required this.viewModel});

  @override
  _HomePageBodyState createState() => _HomePageBodyState(viewModel: viewModel);
}

class _HomePageBodyState extends State<HomePageBody> with WidgetsBindingObserver {
  RestaurantViewModel _viewModel;

  _HomePageBodyState({RestaurantViewModel viewModel}) {
    _viewModel = viewModel;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print("app state is resumed");
      if (await SimplePermissions.checkPermission(Permission.WhenInUseLocation)) {
        _viewModel.updateWithStatus(PermissionStatus.authorized);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RestaurantResult>(
        stream: _viewModel.restaurants,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            print("snapshot has no data");
            return Center(child: Text("Unknown error occured."));
          }
          if (snapshot.hasError) {
            return _createStatusWidget(context, snapshot.error);
          }
          if (snapshot.data.permissionStatus != null) {
            return _createStatusWidget(context, snapshot.data.permissionStatus);
          }
          return Padding(
            padding: EdgeInsets.only(left: 12.0, top: 12.0, right: 8.0, bottom: 28.0),
            child: Center(
              child: ListView.builder(
                  itemCount: snapshot.data.restaurants.length,
                  itemBuilder: (context, index) =>
                      _createExpansionTile(index: index, restaurant: snapshot.data.restaurants[index])),
            ),
          );
        });
  }

  Widget _createExpansionTile({@required int index, @required Restaurant restaurant}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: RestaurantExpansionTile(
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Text(
                  index.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      restaurant.name,
                      style: TextStyle(fontSize: 20.0),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text("~${(restaurant.distance).toStringAsFixed(2)} miles away"),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: _createGoButton(onPressed: () {
                    print("clicked restaurant ${restaurant.name} at ${restaurant.lat},${restaurant.long}");
                    _launchMaps(restaurant.lat, restaurant.long);
                  }))
            ],
          )
        ],
      ),
    );
  }

  MaterialButton _createGoButton({onPressed: VoidCallback}) {
    return MaterialButton(
      color: Colors.purple,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text("Go", style: TextStyle(color: Colors.white)),
        ),
        Icon(
          Icons.arrow_forward,
          color: Colors.white,
        )
      ]),
      onPressed: () {
        onPressed();
      },
    );
  }

  Widget _createStatusWidget(BuildContext context, PermissionStatus status) {
    String statusText;
    Widget statusButtonWidget;
    print("Creating status widget for $status");
    switch (status) {
      case PermissionStatus.denied:
        {
          statusText = "Location permissions not granted.";
          if (Theme.of(context).platform == TargetPlatform.iOS) {
            statusButtonWidget = MaterialButton(
              color: Theme.of(context).primaryColor,
              onPressed: () {
                SimplePermissions.openSettings();
              },
              child: Text("Open Settings", style: TextStyle(color: Colors.white, fontSize: 16.0)),
            );
          }
          break;
        }
      case PermissionStatus.deniedNeverAsk:
        {
          statusText = "Location disabled for this app, please enable in settings to continue.";
          statusButtonWidget = MaterialButton(
            color: Theme.of(context).primaryColor,
            onPressed: () {
              SimplePermissions.openSettings();
            },
            child: Text("Open Settings", style: TextStyle(color: Colors.white, fontSize: 14.0)),
          );
          break;
        }
      case PermissionStatus.authorized:
      case PermissionStatus.notDetermined:
        {
          //user has not been prompted
          statusText = "Use the button on the bottom to begin searching for restaurants.";
          break;
        }
      default:
        {
          print("trying to create status widget for $status");
          statusText = "Unknown error occured when fetching the restaurants";
        }
    }
    final statusTextWidget = Text(
      statusText,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18.0),
    );
    Widget statusWidget;
    if (statusButtonWidget != null) {
      statusWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            statusTextWidget,
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: statusButtonWidget,
            ),
          ],
        ),
      );
    } else {
      statusWidget = Center(child: statusTextWidget);
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      child: statusWidget,
    );
  }

  //https://www.google.com/maps/dir/?api=1&destination=lat,lng
  _launchMaps(double lat, double lng) async {
    const url = 'https://www.google.com/maps/dir/?api=1&destination=';
    final completedUrl = url + "$lat,$lng";
    if (await canLaunch(completedUrl)) {
      print("can launch url");
      await launch(completedUrl);
    }
  }
}
