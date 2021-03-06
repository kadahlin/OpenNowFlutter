import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'open_now_redux.dart';

//Allow the user to select a range via a slider
class DistanceDialog extends StatelessWidget {
  
  static void showDistanceDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => DistanceDialog());
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      content: Container(
        width: 260.0,
        height: 125.0,
        child: Center(
          child: Column(
            children: <Widget>[
              Text("Distance"),
              _DistanceSlider(),
            ],
//              _SearchingAnimation()),
          ),
        ),
      ),
    );
  }
}

class _DistanceSlider extends StatefulWidget {
  @override
  State<_DistanceSlider> createState() => _DistanceSliderState();
}

class _DistanceSliderState extends State<_DistanceSlider> {
  var _sliderValue = 5.0;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<RestaurantResult, ActionCallback>(
      converter: (store) {
        return (action) => store.dispatch(action);
      },
      builder: (context, callback) {
        return Column(
          children: <Widget>[
            Slider(
              value: _sliderValue,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                });
              },
            ),
            Text("${_sliderValue.toInt()} mile${_sliderValue > 1 ? 's' : ''}"),
            MaterialButton(
              onPressed: () {
                callback(loadRestaurantList(_sliderValue));
                Navigator.of(context).pop();
              },
              child: Text("Search"),
            )
          ],
        );
      }
    );
  }
}