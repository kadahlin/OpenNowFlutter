# Open Now

[![Build Status](https://travis-ci.org/kadahlin/OpenNowFlutter.svg?branch=master)](https://travis-ci.org/kadahlin/OpenNowFlutter)

Flutter application to show which restaurants are currently open in a given radius around you.

## Motivation

Getting my feet wet with any new framework I usually make what I call the "Open Now" application. The
app appears simple to the user in that all it does is display the restaurants around their current location
that are currently open. Clicking a location in the list will provide google maps directions.

Internally this touches a lot of different areas in Flutter. The query 
uses the Google Places SDK, http networking, and json serialization. The location permission has to 
be granted and managed when dealing with the user's location. The loading animation is made with the 
recently supported Flare tools by 2dAnimations.

Although it is overkill this type of app I like to implement an architecture
to make the code clean and potentially scalable. The state in this app is managed using the Redux pattern with
`flutter_redux` and `redux_thunk`. 