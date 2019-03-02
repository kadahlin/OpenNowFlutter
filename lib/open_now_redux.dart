import 'package:open_now/restaurant_api.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:simple_permissions/simple_permissions.dart';

enum SortingMethod { alphabetical, distance }
enum UiStatus { Prompt, Authorized, Denied, DeniedDontAsk, Loading, Loaded, Error }

typedef ActionCallback = Function(dynamic action);

class RestaurantResult {
  UiStatus uiStatus;
  List<Restaurant> restaurants;
  Exception exception;

  RestaurantResult(this.uiStatus, this.restaurants, {this.exception});
}

class RestaurantLoadingAction {}

class SortRestaurantAction {
  SortingMethod method;

  SortRestaurantAction(this.method);
}

class RestaurantLoadErrorAction {
  Exception exception;

  RestaurantLoadErrorAction(this.exception);
}

class RestaurantsLoadedAction {
  List<Restaurant> restaurants;

  RestaurantsLoadedAction(this.restaurants);
}

class UpdatePermissionAction {
  PermissionStatus status;

  UpdatePermissionAction(this.status);
}

ThunkAction<RestaurantResult> loadRestaurantList(double distance) {
  return (Store<RestaurantResult> store) async {
    store.dispatch(RestaurantLoadingAction());
    List<Restaurant> restaurants;
    try {
      restaurants = await getRestaurants(distance);
    } catch (e) {
      print("Error when loading from api");
      store.dispatch(RestaurantLoadErrorAction(e));
      return;
    }
    print("there were ${restaurants.length} total results from the query");
    store.dispatch(RestaurantsLoadedAction(restaurants));
  };
}

RestaurantResult appReducers(RestaurantResult state, dynamic action) {
  if (action is SortRestaurantAction) {
    return _sortRestaurants(state, action);
  } else if (action is UpdatePermissionAction) {
    return _updatePermissionStatus(state, action);
  } else if (action is RestaurantLoadErrorAction) {
    return RestaurantResult(UiStatus.Error, null, exception: action.exception);
  } else if (action is RestaurantLoadingAction) {
    return RestaurantResult(UiStatus.Loading, state.restaurants);
  } else if (action is RestaurantsLoadedAction) {
    return RestaurantResult(UiStatus.Loaded, action.restaurants);
  }
  return state;
}

RestaurantResult _sortRestaurants(RestaurantResult state, SortRestaurantAction action) {
  state.restaurants.sort((one, two) {
    switch (action.method) {
      case SortingMethod.alphabetical:
        {
          return one.name.toLowerCase().compareTo(two.name.toLowerCase());
        }
      case SortingMethod.distance:
        {
          return (one.distance * 100 - two.distance * 100).toInt();
        }
    }
  });
  return RestaurantResult(state.uiStatus, state.restaurants);
}

RestaurantResult _updatePermissionStatus(RestaurantResult state, UpdatePermissionAction action) {
  final currentStatus = state.uiStatus;
  final uiStatus = convertToUiStatus(action.status);
  print("updating status from $currentStatus to $uiStatus");
  if (currentStatus != UiStatus.Loaded && currentStatus != uiStatus) {
    return (RestaurantResult(uiStatus, null));
  }
  return state;
}

UiStatus convertToUiStatus(PermissionStatus status) {
  switch (status) {
    case PermissionStatus.authorized:
    case PermissionStatus.notDetermined:
    case PermissionStatus.restricted:
      return UiStatus.Prompt;
    case PermissionStatus.deniedNeverAsk:
      return UiStatus.DeniedDontAsk;
    case PermissionStatus.denied:
      return UiStatus.Denied;
  }
  return UiStatus.Prompt;
}
