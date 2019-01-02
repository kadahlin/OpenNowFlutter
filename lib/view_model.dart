import 'package:flutter/material.dart';

abstract class ViewModel {
  void dispose();
}

///View Model Provider based on the BLoC pattern series of articles written for flutter
class ViewModelProvider<T extends ViewModel> extends StatefulWidget {
  ViewModelProvider({
    Key key,
    @required this.child,
    @required this.bloc,
  }) : super(key: key);

  final T bloc;
  final Widget child;

  @override
  _ViewModelProviderState<T> createState() => _ViewModelProviderState<T>();

  static T of<T extends ViewModel>(BuildContext context) {
    final type = _typeOf<ViewModelProvider<T>>();
    ViewModelProvider<T> provider = context.ancestorWidgetOfExactType(type);
    return provider.bloc;
  }

  static Type _typeOf<T>() => T;
}

class _ViewModelProviderState<T> extends State<ViewModelProvider<ViewModel>> {
  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
