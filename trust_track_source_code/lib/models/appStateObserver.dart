import 'package:flutter/widgets.dart';

class AppStateObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is resumed from the background
      // Restore your app's state here
    } else if (state == AppLifecycleState.paused) {
      // App is being paused (closed)
      // Save your app's state here
    }
  }
}
