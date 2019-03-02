import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'home_page.dart';
import 'open_now_redux.dart';

class OpenNowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final store = Store<RestaurantResult>(
        appReducers,
        middleware: [thunkMiddleware],
        initialState: RestaurantResult(UiStatus.prompt, null));

    return StoreProvider<RestaurantResult>(
      store: store,
      child: MaterialApp(
        title: 'Open Now',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: HomePage(),
      ),
    );
  }
}

void main() => runApp(OpenNowApp());
