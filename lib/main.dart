import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'categories.dart';


void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  runApp(MyApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tag Generator',
      theme: new ThemeData(          // Add the 3 lines from here... 
        primaryColor: Colors.red,
      ),                     
      home: Tags(routeObserver: routeObserver,),
      navigatorObservers: [routeObserver],
    );
  }
}