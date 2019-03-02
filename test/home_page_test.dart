import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_now/home_page.dart';
import 'package:open_now/open_now_redux.dart';
import 'package:open_now/restaurant_api.dart';
import 'package:redux/redux.dart';

void main() {
  testWidgets('any loaded results should disappear if an error is passed to the home page',
      (WidgetTester tester) async {
    final store = _getMockStore();
    final widget = _getTestHomePage(store);

    store.dispatch(RestaurantsLoadedAction([
      Restaurant(name: "test_restaurant", lat: 1.0, long: 1.0),
      Restaurant(name: "test_restaurant2", lat: 1.0, long: 1.0)
    ]));

    await tester.pumpWidget(widget);
    Finder restaurantOne = find.text("test_restaurant");
    final restaurantTwo = find.text("test_restaurant2");
    expect(restaurantOne, findsOneWidget);
    expect(restaurantTwo, findsOneWidget);

    store.dispatch(RestaurantLoadErrorAction(Exception("test")));
    await tester.pumpWidget(widget);
    restaurantOne = find.text("test_restaurant");
    expect(restaurantOne, findsNothing);
  });

  testWidgets('loading action should propagate to the home page', (WidgetTester tester) async {
    final store = _getMockStore();
    final widget = _getTestHomePage(store);
    final testKey = Key("loading_animation");
    await tester.pumpWidget(widget);
    expect(find.byKey(testKey), findsNothing);

    store.dispatch(RestaurantLoadingAction());
    await tester.pumpWidget(widget);

    expect(find.byKey(testKey), findsOneWidget);
  });
}

Store<RestaurantResult> _getMockStore() => Store<RestaurantResult>(
      appReducers,
      initialState: RestaurantResult(UiStatus.Prompt, null),
    );

Widget _getTestHomePage(Store<RestaurantResult> store) =>
    StoreProvider(store: store, child: MaterialApp(home: HomePage()));
