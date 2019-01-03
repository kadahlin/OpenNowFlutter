import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'haversine.dart';
import 'restaurant.dart';
import 'view_model.dart';

const String URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?";
const double METERS_PER_MILE = 1609.34;

enum SortingMethod { alphabetical, distance }
enum UiStatus { Prompt, Authorized, Denied, DeniedDontAsk, Loading, Loaded}

///Data class that gets emitted from the stream that contains any data returned from the API
///along with the current permission status
class RestaurantResult {
  UiStatus uiStatus;
  List<Restaurant> restaurants;

  RestaurantResult(this.uiStatus, this.restaurants);
}

///View Model that the app widgets can subscribe to for place updates
class RestaurantViewModel extends ViewModel {

  //The initial state of the data is not determined, we have not yet queried for the location permission
  final _resultSubject =
      BehaviorSubject<RestaurantResult>(seedValue: RestaurantResult(UiStatus.Prompt, null));

  Observable<RestaurantResult> get restaurants => _resultSubject.stream;

  List<Restaurant> _currentRestaurants = [];

  loadRestaurantList(double distance) async {
    _resultSubject.add(RestaurantResult(UiStatus.Loading, null));
    Map<String, double> location;
    try {
      location = await Location().getLocation();
    } catch (e) {
      print(e);
      _resultSubject.addError(e);
      return;
    }
    final lat = location['latitude'];
    final long = location['longitude'];

    final restaurants = <Restaurant>[];
    String pageToken;
    do {
      //To use real data (ensure key.json contains your API key)
      final url = await _createUrl(lat, long, distance, pageToken);
      final response = await http.get(Uri.parse(url));
      print(response.body);
      final decodedJson = jsonDecode(response.body);

      //To use the example data and simulate a delay for the animation
//      final decodedJson = jsonDecode(EXAMPLE);
//      await Future.delayed(const Duration(
//          seconds: 3));

      restaurants.addAll(_getRestaurantsFromJson(decodedJson));
      pageToken = decodedJson['next_page_token'];
      if (pageToken != null) {
        await Future.delayed(const Duration(
            seconds: 2)); //There is a slight delay between PlacesSdk 'next page' responses, 2 seconds should be safe
      }
    } while (pageToken != null);

    restaurants.forEach((restaurant) {
      restaurant.distance =
          Haversine.getDistanceBetween(lat1: lat, long1: long, lat2: restaurant.lat, long2: restaurant.long);
    });
    _currentRestaurants = restaurants;
    print("there were ${_currentRestaurants.length} total results from the query");
    _resultSubject.add(RestaurantResult(UiStatus.Loaded, _currentRestaurants));
  }

  ///Sort the current list of restaurants by a certain [SortingMethod]
  sortBy(SortingMethod method) async {
    if (_currentRestaurants.isEmpty) return;
    _currentRestaurants.sort((one, two) {
      switch (method) {
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
    _resultSubject.add(RestaurantResult(null, _currentRestaurants));
  }

  void updateWithStatus(PermissionStatus status) async {
    final latest = _resultSubject.value;
    final uiStatus = convertToUiStatus(status);
    print("updating status from ${latest.uiStatus} to $uiStatus");
    if (latest.uiStatus != UiStatus.Loaded && latest.uiStatus != uiStatus) {
      _resultSubject.add(RestaurantResult(uiStatus, null));
    }
  }

  Future<String> _createUrl(double lat, double long, double distance, String nextPageToken) async {
    final meterDistance = distance * METERS_PER_MILE;
    final buffer = StringBuffer(URL);
    if (nextPageToken != null) {
      buffer.write("pagetoken=$nextPageToken");
    } else {
      buffer
        ..write("location=$lat,$long")
        ..write("&radius=$meterDistance")
        ..write("&type=restaurant")
        ..write("&opennow=true");
    }
    buffer.write("&key=${await _getApiKey()}");
    return buffer.toString();
  }

  List<Restaurant> _getRestaurantsFromJson(dynamic decodedJson) {
    List<Restaurant> restaurants = [];
    for (final result in decodedJson['results']) {
      final location = result['geometry']['location'];
      final lat = location['lat'];
      final long = location['lng'];
      restaurants.add(Restaurant(name: result['name'], lat: lat, long: long));
    }
    return restaurants;
  }

  void dispose() {
    _resultSubject.close();
  }

  Future<String> _getApiKey() async {
    final encodedJson = await rootBundle.loadString('key.json');
    final decodedJson = jsonDecode(encodedJson);
    return decodedJson["places_key"];
  }

  UiStatus convertToUiStatus(PermissionStatus status) {
    switch(status) {
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
}

//example taken from https://developers.google.com/places/web-service/search
//substitute this instead of the http await + response.body to test without using your places quota limit.
const EXAMPLE = '''
{
  "html_attributions": [],
  "results": [
    {
      "geometry": {
        "location": {
          "lat": -33.870775,
          "lng": 151.199025
        }
      },
      "icon": "http://maps.gstatic.com/mapfiles/place_api/icons/travel_agent-71.png",
      "id": "21a0b251c9b8392186142c798263e289fe45b4aa",
      "name": "Rhythmboat Cruises",
      "opening_hours": {
        "open_now": true
      },
      "photos": [
        {
          "height": 270,
          "html_attributions": [],
          "photo_reference": "CnRnAAAAF-LjFR1ZV93eawe1cU_3QNMCNmaGkowY7CnOf-kcNmPhNnPEG9W979jOuJJ1sGr75rhD5hqKzjD8vbMbSsRnq_Ni3ZIGfY6hKWmsOf3qHKJInkm4h55lzvLAXJVc-Rr4kI9O1tmIblblUpg2oqoq8RIQRMQJhFsTr5s9haxQ07EQHxoUO0ICubVFGYfJiMUPor1GnIWb5i8",
          "width": 519
        }
      ],
      "place_id": "ChIJyWEHuEmuEmsRm9hTkapTCrk",
      "scope": "GOOGLE",
      "alt_ids": [
        {
          "place_id": "D9iJyWEHuEmuEmsRm9hTkapTCrk",
          "scope": "APP"
        }
      ],
      "reference": "CoQBdQAAAFSiijw5-cAV68xdf2O18pKIZ0seJh03u9h9wk_lEdG-cP1dWvp_QGS4SNCBMk_fB06YRsfMrNkINtPez22p5lRIlj5ty_HmcNwcl6GZXbD2RdXsVfLYlQwnZQcnu7ihkjZp_2gk1-fWXql3GQ8-1BEGwgCxG-eaSnIJIBPuIpihEhAY1WYdxPvOWsPnb2-nGb6QGhTipN0lgaLpQTnkcMeAIEvCsSa0Ww",
      "types": [ "travel_agency", "restaurant", "food", "establishment"],
      "vicinity": "Pyrmont Bay Wharf Darling Dr, Sydney"
    },
    {
      "geometry": {
        "location": {
          "lat": -33.866891,
          "lng": 151.200814
        }
      },
      "icon": "http://maps.gstatic.com/mapfiles/place_api/icons/restaurant-71.png",
      "id": "45a27fd8d56c56dc62afc9b49e1d850440d5c403",
      "name": "Private Charter Sydney Habour Cruise",
      "photos": [
        {
          "height": 426,
          "html_attributions": [],
          "photo_reference": "CnRnAAAAL3n0Zu3U6fseyPl8URGKD49aGB2Wka7CKDZfamoGX2ZTLMBYgTUshjr-MXc0_O2BbvlUAZWtQTBHUVZ-5Sxb1-P-VX2Fx0sZF87q-9vUt19VDwQQmAX_mjQe7UWmU5lJGCOXSgxp2fu1b5VR_PF31RIQTKZLfqm8TA1eynnN4M1XShoU8adzJCcOWK0er14h8SqOIDZctvU",
          "width": 640
        }
      ],
      "place_id": "ChIJqwS6fjiuEmsRJAMiOY9MSms",
      "scope": "GOOGLE",
      "reference": "CpQBhgAAAFN27qR_t5oSDKPUzjQIeQa3lrRpFTm5alW3ZYbMFm8k10ETbISfK9S1nwcJVfrP-bjra7NSPuhaRulxoonSPQklDyB-xGvcJncq6qDXIUQ3hlI-bx4AxYckAOX74LkupHq7bcaREgrSBE-U6GbA1C3U7I-HnweO4IPtztSEcgW09y03v1hgHzL8xSDElmkQtRIQzLbyBfj3e0FhJzABXjM2QBoUE2EnL-DzWrzpgmMEulUBLGrtu2Y",
      "types": [ "restaurant", "food", "establishment"],
      "vicinity": "Australia"
    },
    {
      "geometry": {
        "location": {
          "lat": -33.870943,
          "lng": 151.190311
        }
      },
      "icon": "http://maps.gstatic.com/mapfiles/place_api/icons/restaurant-71.png",
      "id": "30bee58f819b6c47bd24151802f25ecf11df8943",
      "name": "Bucks Party Cruise",
      "opening_hours": {
        "open_now": true
      },
      "photos": [
        {
          "height": 600,
          "html_attributions": [],
          "photo_reference": "CnRnAAAA48AX5MsHIMiuipON_Lgh97hPiYDFkxx_vnaZQMOcvcQwYN92o33t5RwjRpOue5R47AjfMltntoz71hto40zqo7vFyxhDuuqhAChKGRQ5mdO5jv5CKWlzi182PICiOb37PiBtiFt7lSLe1SedoyrD-xIQD8xqSOaejWejYHCN4Ye2XBoUT3q2IXJQpMkmffJiBNftv8QSwF4",
          "width": 800
        }
      ],
      "place_id": "ChIJLfySpTOuEmsRsc_JfJtljdc",
      "scope": "GOOGLE",
      "reference": "CoQBdQAAANQSThnTekt-UokiTiX3oUFT6YDfdQJIG0ljlQnkLfWefcKmjxax0xmUpWjmpWdOsScl9zSyBNImmrTO9AE9DnWTdQ2hY7n-OOU4UgCfX7U0TE1Vf7jyODRISbK-u86TBJij0b2i7oUWq2bGr0cQSj8CV97U5q8SJR3AFDYi3ogqEhCMXjNLR1k8fiXTkG2BxGJmGhTqwE8C4grdjvJ0w5UsAVoOH7v8HQ",
      "types": [ "restaurant", "food", "establishment"],
      "vicinity": "37 Bank St, Pyrmont"
    },
    {
      "geometry": {
        "location": {
          "lat": -33.867591,
          "lng": 151.201196
        }
      },
      "icon": "http://maps.gstatic.com/mapfiles/place_api/icons/travel_agent-71.png",
      "id": "a97f9fb468bcd26b68a23072a55af82d4b325e0d",
      "name": "Australian Cruise Group",
      "opening_hours": {
        "open_now": true
      },
      "photos": [
        {
          "height": 242,
          "html_attributions": [],
          "photo_reference": "CnRnAAAABjeoPQ7NUU3pDitV4Vs0BgP1FLhf_iCgStUZUr4ZuNqQnc5k43jbvjKC2hTGM8SrmdJYyOyxRO3D2yutoJwVC4Vp_dzckkjG35L6LfMm5sjrOr6uyOtr2PNCp1xQylx6vhdcpW8yZjBZCvVsjNajLBIQ-z4ttAMIc8EjEZV7LsoFgRoU6OrqxvKCnkJGb9F16W57iIV4LuM",
          "width": 200
        }
      ],
      "place_id": "ChIJrTLr-GyuEmsRBfy61i59si0",
      "scope": "GOOGLE",
      "reference": "CoQBeQAAAFvf12y8veSQMdIMmAXQmus1zqkgKQ-O2KEX0Kr47rIRTy6HNsyosVl0CjvEBulIu_cujrSOgICdcxNioFDHtAxXBhqeR-8xXtm52Bp0lVwnO3LzLFY3jeo8WrsyIwNE1kQlGuWA4xklpOknHJuRXSQJVheRlYijOHSgsBQ35mOcEhC5IpbpqCMe82yR136087wZGhSziPEbooYkHLn9e5njOTuBprcfVw",
      "types": [ "travel_agency", "restaurant", "food", "establishment"],
      "vicinity": "32 The Promenade, King Street Wharf 5, Sydney"
    }
  ],
  "status": "OK"
}
''';
