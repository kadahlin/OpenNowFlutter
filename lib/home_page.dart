import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'distance_dialog.dart';
import 'home_page_body.dart';
import 'restaurant_view_model.dart';
import 'view_model.dart';

///Container for app, includes the app bar and the fab
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final RestaurantViewModel viewModel = ViewModelProvider.of<RestaurantViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Open Now"),
        actions: <Widget>[
          PopupMenuButton<SortingMethod>(
            onSelected: (method) => viewModel.sortBy(method),
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
      body: HomePageBody(
        viewModel: viewModel,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final status = await SimplePermissions.requestPermission(Permission.WhenInUseLocation);
          if (status == PermissionStatus.authorized) {
            DistanceDialog.showDistanceDialog(context);
          } else {
            viewModel.updateWithStatus(status);
          }
        },
        child: Icon(Icons.restaurant),
      ),
    );
  }
}

class _SearchingAnimation extends StatefulWidget {
  _SearchingAnimationState createState() => _SearchingAnimationState();
}

class _SearchingAnimationState extends State<_SearchingAnimation> with SingleTickerProviderStateMixin {
  Animation<double> _heightAnimation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 5000), vsync: this);
    _heightAnimation = Tween(begin: 0.0, end: 2.0 * math.pi).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: _heightAnimation.value,
        child: Text("Spinning"),
      ),
    );
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
