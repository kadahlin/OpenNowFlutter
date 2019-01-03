# Open Now

Flutter application to show which restaurants are currently open in a given radius around you.

## Motivation

Getting my feet wet with any new framework I usually make what I call the "Open Now" application. The
app appears simple to the user in that all it does is display the restaurants around their current location
that are currently open. Clicking a location in the list will provide google maps directions.

Internally this touches a lot of different areas in the new framework. The query 
uses the Google Places SDK, http networking, and json serialization. The Location permission has to 
be granted and managed when dealing with the user's location. The loading animation is made with the 
recently supported Flare tools by 2dAnimations.

Although it is overkill for an app like this I like to use Rx and implement some form of architecture
to make the code clean and potentially scalable. The state in this app is managed by the BLoC pattern designed by 
Google and the UI observes a Rx Dart stream. 