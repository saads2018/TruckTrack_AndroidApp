
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:background_location/background_location.dart';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_track/models/api.services.dart';
import 'package:trust_track/screens/onBoarding/onBoarding_screen.dart';

import 'models/appStateObserver.dart';
import 'models/deliveriesList.dart';

late final CameraDescription firstCamera;
late CameraController? _controller;
late Future<void> _initializeControllerFuture;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appStateObserver = AppStateObserver();
  WidgetsBinding.instance.addObserver(appStateObserver);

  await APIservices.loadBaseURL();
  await APIservices.loadUserName();
  await APIservices.loadPassword();

  availableCameras().then((value){
    firstCamera = value.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.low,
    );
    _initializeControllerFuture = _controller!.initialize();
  });

  //await AndroidAlarmManager.initialize();
  //_startBackgroundTask();
  await initializeService();

  runApp(TruckTrackApp());

}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }


  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'TruckTrack SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ), iosConfiguration: IosConfiguration(
    // auto start service
    autoStart: true,

    // this will be executed when app is in foreground in separated isolate
    onForeground: onStart,

    // you have to enable background fetch capability on xcode project
    onBackground: onIosBackground,
  ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  //SharedPreferences preferences = await SharedPreferences.getInstance();
  //await preferences.setString("hello", "world");

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'TruckTrack SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        DateFormat dateFormat = DateFormat('dd-MM-yyyy HH:mm'); // 'HH' is for 24-hour, 'mm' is for minutes
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "Location is Being Updated",
          content: "Updated at ${dateFormat.format(DateTime.now())}",
        );
      }
    }

    /// you can see this log in logcat
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    try {
      getLocation();
    }
    catch(e) {

    }
    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

void showToastMessage(String message)
{
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT, // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
    gravity: ToastGravity.BOTTOM, // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
    backgroundColor: Colors.grey, // Background color of the toast
    textColor: Colors.white, // Text color of the toast
  );
}

void myBackgroundTask()
async {
  showToastMessage("Sending Coordinates");
  bool done = false;
  await APIservices.loadBaseURL();
  await APIservices.loadUserName();

  try{
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(serviceEnabled && (APIservices.savedUsername!='' || APIservices.savedUsername!=null))
    {
      await APIservices.fetchData('Master/GetDeliveries').then((response) async {
        Iterable list = json.decode(response.body);
        var listT = json.decode(response.body);
        List<DeliveriesList> deliveryList = List<DeliveriesList>.empty();
        deliveryList =
            list.map((model) => DeliveriesList.fromObject(model)).toList();
        var delivery = deliveryList.firstWhere((element) => element.driverUserName == APIservices.savedUsername && element.deliveryStatus != "Ended");
        var deliveryIndex = deliveryList.indexOf(delivery);

        if(delivery!=null && delivery.deliveryStatus == "Started")
        {
          DateTime now = DateTime.now();
          String formattedTime = DateFormat('H:mm').format(now);

          await BackgroundLocation.startLocationService();
          List<Point> points = [];

          if(!(listT[deliveryIndex]["coordinates"].toString().toLowerCase().contains("null")))
          {
            for(final coord in listT[deliveryIndex]["coordinates"])
            {
              Point point = Point(coord["x"],coord["y"]);
              points.add(point);
            }
          }


          BackgroundLocation.getLocationUpdates((location) async {
            if(!done && (points.isEmpty || (points.last.x != location.latitude && points.last.y != location.longitude)) )
            {
              done = true;
              await APIservices.postData("Master/SaveCoordinates?id=${delivery.deliveryId}&latitude=${location.latitude}&longitude=${location.longitude}&time=$formattedTime&speed=${location.speed?.toStringAsFixed(2)}");
              showToastMessage("Coordinates Saved");
              points.add(Point(location.latitude, location.longitude));
            }
            else{
              showToastMessage("Coordinates Not Saved");
            }
            await BackgroundLocation.stopLocationService();
          });
        }
        else{
          showToastMessage("Coordinates Not Saved");
        }
      });
    }
    else{
      showToastMessage("Coordinates Not Saved");
    }
  }
  catch(e){
    showToastMessage("Coordinates Not Saved");
  }
}


void getLocation()
async {
  //showToastMessage("Sending Coordinates");
  bool done = false;
  var email = await readDataFromFile("email");
  var ip = await readDataFromFile("ip");

  if(ip!=null && email!=null)
    {
      APIservices.saveBaseURL(ip.toString());
      APIservices.saveUsername(email.toString());
    }

  try{
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(serviceEnabled && (APIservices.savedUsername!='' || APIservices.savedUsername!=null))
    {
      await APIservices.fetchData('Master/GetDeliveries').then((response) async {
        Iterable list = json.decode(response.body);
        var listT = json.decode(response.body);
        List<DeliveriesList> deliveryList = List<DeliveriesList>.empty();
        deliveryList =
            list.map((model) => DeliveriesList.fromObject(model)).toList();
        var delivery = deliveryList.firstWhere((element) => element.driverUserName == APIservices.savedUsername && element.deliveryStatus != "Ended");
        var deliveryIndex = deliveryList.indexOf(delivery);

        if(delivery!=null && delivery.deliveryStatus == "Started")
        {
          DateTime now = DateTime.now();
          String formattedTime = DateFormat('H:mm').format(now);

          List<Point> points = [];
          if(!(listT[deliveryIndex]["coordinates"].toString().toLowerCase().contains("null")))
          {
            for(final coord in listT[deliveryIndex]["coordinates"])
            {
              Point point = Point(coord["x"],coord["y"]);
              points.add(point);
            }
          }

          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
          );

          if(!done && (points.isEmpty || (points.last.x != position.latitude && points.last.y != position.longitude)) )
          {
            done = true;
            await APIservices.postData("Master/SaveCoordinates?id=${delivery.deliveryId}&latitude=${position.latitude}&longitude=${position.longitude}&time=$formattedTime&speed=${position.speed?.toStringAsFixed(2)}");
            //showToastMessage("Coordinates Saved");
            points.add(Point(position.latitude, position.longitude));
          }
          else{
            //showToastMessage("Coordinates Not Saved");
          }

        }
        else{
          //showToastMessage("Coordinates Not Saved");
        }
      });
    }
    else{
      //showToastMessage("Coordinates Not Saved");
    }
  }
  catch(e){
    //showToastMessage("Coordinates Not Saved");
  }
}


Future<String?> readDataFromFile(String fileName) async {
  try {
    final file = File('${(await getApplicationDocumentsDirectory()).path}/$fileName.txt');
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (e) {
    // Handle error
  }
  return null; // Return null if file doesn't exist or there's an error
}



/*
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // Do your work here...
  BackgroundFetch.finish(taskId);
}
*/

/*void callBack() {
  Workmanager().executeTask((taskName, inputData) async {
    print("Task: $taskName");
    await APIservices.loadBaseURL();

    int id = inputData?['id'];
    double latitude = inputData?['latitude'];
    double longitude = inputData?['longitude'];
    String time = inputData?['time'];
    String speed = inputData?['speed'];

    print("$latitude\n $longitude \n $time \n $speed");

    //await APIservices.postData("Master/SaveCoordinates?id=$id&latitude=$latitude&longitude=$longitude&time=$time&speed=$speed");

    return Future.value(true);
  });
}
*/


/*void configureBackgroundFetch() {
  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval:1, // Minimum interval in minutes.
      stopOnTerminate: true, // Set to true if you want to stop background fetch when the app is terminated.
      enableHeadless: true, // Set to true to enable headless execution of the background task.
    ),
    backgroundFetchHeadlessTask,
  );
}*/

// void loadSavedIPAddress() async {
//   final prefs = await SharedPreferences.getInstance();
//   String? savedIPAddress = prefs.getString('ipAddress');
//   if (savedIPAddress != null) {
//     APIservices.baseURL = savedIPAddress;
//   }
// }

MaterialColor buildMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}


class TruckTrackApp extends StatelessWidget {

  int colorCode = 0XFF6b619d;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TruckTrack Page',
      theme: ThemeData(
        primarySwatch: buildMaterialColor(Color(colorCode)),
        scaffoldBackgroundColor: Color(colorCode),
        splashColor: Color(colorCode),
      ),
      home: onBoardingScreen(
        controller: _controller,
        initializeControllerFuture: _initializeControllerFuture,
      ),
    );
  }
}
