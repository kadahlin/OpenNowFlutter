import 'package:flutter/material.dart';

import 'home_page.dart';
import 'restaurant_view_model.dart';
import 'view_model.dart';

class OpenNowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<RestaurantViewModel>(
      child: MaterialApp(
        title: 'Open Now',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: HomePage(),
      ),
      bloc: RestaurantViewModel(),
    );
  }
}

void main() => runApp(OpenNowApp());
