import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:open_now/restaurant_api.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'open_now_redux.dart';
import 'restaurant_expansion_tile.dart';

class HomePageBody extends StatefulWidget {
  final ActionCallback storeCallback;

  HomePageBody({@required this.storeCallback});

  @override
  _HomePageBodyState createState() => _HomePageBodyState(storeCallback: storeCallback);
}

class _HomePageBodyState extends State<HomePageBody> with WidgetsBindingObserver {
  ActionCallback storeCallback;

  _HomePageBodyState({@required this.storeCallback});

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
        storeCallback(UpdatePermissionAction(PermissionStatus.authorized));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<RestaurantResult, RestaurantResult>(
        converter: (store) => store.state,
        builder: (context, result) {
          if (result.exception != null) {
            return _createStatusWidget(context, result.uiStatus);
          }
          if (result.uiStatus != UiStatus.Loaded) {
            return _createStatusWidget(context, result.uiStatus);
          }
          return Padding(
            padding: EdgeInsets.only(left: 12.0, top: 12.0, right: 8.0, bottom: 28.0),
            child: Center(
              child: ListView.builder(
                  itemCount: result.restaurants.length,
                  itemBuilder: (context, index) =>
                      _createExpansionTile(index: index, restaurant: result.restaurants[index])),
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

  ///Create widget that represents the body in this current UI state
  Widget _createStatusWidget(BuildContext context, UiStatus status) {
    String statusText;
    Widget statusButtonWidget;
    print("Creating status widget for $status");
    switch (status) {
      case UiStatus.Loading:
        {
          return FlareActor(
            "ui_assets/open_now_animation.flr",
            animation: "searching",
          );
        }
      case UiStatus.Denied:
        {
          statusText = "Location permissions are not granted.";
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
      case UiStatus.DeniedDontAsk:
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
      case UiStatus.Prompt:
      case UiStatus.Authorized:
        {
          //user has not been prompted
          statusText = "Use the button on the bottom to begin searching for restaurants.";
          break;
        }
      case UiStatus.Error:
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
