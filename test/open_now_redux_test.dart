// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:open_now/open_now_redux.dart';
import 'package:open_now/restaurant_api.dart';
import 'package:redux/redux.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:test/test.dart';

final aRestaurant = Restaurant(name: "A", lat: 1.0, long: 1.0, distance: 1.0);
final bRestaurant = Restaurant(name: "B", lat: 1.0, long: 1.0, distance: 3.0);
final cRestaurant = Restaurant(name: "C", lat: 1.0, long: 1.0, distance: 2.0);

void main() {
  group("Sync operations", () {
    test('Exception actions should load the exception into the state', () {
      final store = _getDefaultStore();

      final exception = Exception("test exception");
      store.dispatch(RestaurantLoadErrorAction(exception));

      expect(store.state.exception, exception);
    });

    test("Sorting methods should create a new list inside the state", () {
      final store = Store<RestaurantResult>(appReducers,
          initialState: RestaurantResult(UiStatus.loaded, [bRestaurant, cRestaurant, aRestaurant]));

      store.dispatch(SortRestaurantAction(SortingMethod.alphabetical));
      expect(store.state.restaurants, [aRestaurant, bRestaurant, cRestaurant]);

      store.dispatch(SortRestaurantAction(SortingMethod.distance));
      expect(store.state.restaurants, [aRestaurant, cRestaurant, bRestaurant]);
    });

    test('synchronous load restaurants should populate the list', () {
      final store = _getDefaultStore();

      store.dispatch(RestaurantsLoadedAction([aRestaurant, bRestaurant]));
      expect(store.state.uiStatus, UiStatus.loaded);
      expect(store.state.restaurants, [aRestaurant, bRestaurant]);
    });

    test('permission status should translate into ui status', () {
      final store = _getDefaultStore();

      store.dispatch(UpdatePermissionAction(PermissionStatus.authorized));
      expect(store.state.uiStatus, UiStatus.prompt);
      store.dispatch(UpdatePermissionAction(PermissionStatus.notDetermined));
      expect(store.state.uiStatus, UiStatus.prompt);
      store.dispatch(UpdatePermissionAction(PermissionStatus.deniedNeverAsk));
      expect(store.state.uiStatus, UiStatus.deniedDontAsk);
      store.dispatch(UpdatePermissionAction(PermissionStatus.denied));
      expect(store.state.uiStatus, UiStatus.denied);
      store.dispatch(UpdatePermissionAction(PermissionStatus.restricted));
      expect(store.state.uiStatus, UiStatus.prompt);
    });

    test('loading action correctly updates ui status', () {
      final store = _getDefaultStore();
      store.dispatch(RestaurantLoadingAction());
      expect(store.state.uiStatus, UiStatus.loading);
    });
  });
}

Store<RestaurantResult> _getDefaultStore() => Store<RestaurantResult>(
      appReducers,
      initialState: RestaurantResult(UiStatus.prompt, null),
    );
