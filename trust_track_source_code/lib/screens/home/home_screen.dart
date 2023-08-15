import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trust_track/models/ImageInput.dart';
import 'package:trust_track/models/deliveriesList.dart';
import 'package:trust_track/models/deliveryDetails.dart';
import 'package:trust_track/screens/home/components/FormScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/customersList.dart';
import '../../models/api.services.dart';
import '../../models/fort.dart';
import '../../models/users.dart';
import '../../utilis/entry_point.dart';
import '../onBoarding/onBoarding_screen.dart';
import 'components/fort_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.data, this.controller, required this.initializeControllerFuture}) : super(key: key);
  final String data;
  final CameraController? controller;
  final Future<void> initializeControllerFuture;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  Timer? timer;
  List<CustomersList> mainCustomerList=[];
  List<Fort> mainRoutesList=[];
  bool isLoading = false;
  bool isButtonEnabled = true;
  Geolocator _geolocator = Geolocator();
  Position? _currentPosition;
  String? _journeyStatus;
  List<CustomersList> custList = List<CustomersList>.empty();
  String deliveredDets="";
  String? _currentAddress;
  String? _travellingTo = 'No Pending Deliveries';
  int noOfRoutes=0;
  bool _isShimmering = true;
  bool _address2Check = false;
  String fullname = '';
  Map<String,bool> pending= {};
  List<String> completedListB = [];
  List<bool> _isExpandedList = [false, false];
  bool endJourney = false;
  bool start = false;
  TextEditingController _startingMileage = TextEditingController(text: "");
  TextEditingController _endingMileage = TextEditingController(text: "");
  TextEditingController _distanceTravelled = TextEditingController(text: "");
  TextEditingController _startingFuel = TextEditingController(text: "");
  TextEditingController _endingFuel = TextEditingController(text: "");
  TextEditingController _fuelConsumption = TextEditingController(text: "");
  List<String> routesList = [];
  List<String> addressesList = [];
  int deliveryID=-1;
  late DeliveriesList storeDelivery;
  late String deliveryFirst;
  String dropdownvalue = "Empty Tank";
  String dropdownvalue_Final = "Empty Tank";
  String truckNumber = "";
  String startingMileage = "";
  TextEditingController _controllerTruck = TextEditingController(text: "");
  TextEditingController _controllerMileage = TextEditingController(text: "");
  bool txtField1Enabled = true;
  bool txtField2Enabled = true;

  final Map<String,int> fuelMs = <String,int>{
    'Empty Tank': 0,
    '25 % Full': 25,
    'Half Tank': 50,
    '75 % Full': 75,
    'Full Tank': 100,
  };

  var globalItems = [
    'Empty Tank',
    '25 % Full',
    'Half Tank',
    '75 % Full',
    'Full Tank',
  ];

  var items = [
    'Empty Tank',
    '25 % Full',
    'Half Tank',
    '75 % Full',
    'Full Tank',
  ];

  //late final CameraDescription firstCamera;

  void refresh(){
    setState(() {
      getRouteData();
    });
  }

  @override
  void initState() {
    super.initState();
    _handleLocationPermission();
    print("CHECK");

    getCustomersList().then((value){
      getRouteData().then((value) {
        setState(()  {
          _isShimmering = false;
        });
        getUserData(widget.data);
        timer = Timer.periodic(Duration(seconds: 5), (_) {
          _getCurrentPosition(widget.data);
        });
      });
    });
  }



  void _handleMessage(List<Object?>? arguments) {
    print('Received message: $arguments');
  }

  Future<void> getCustomersList() async {
    await APIservices.fetchData('Master/GetCustomers').then((response) async {
      Iterable list = json.decode(response.body);
      custList = list.map((model) => CustomersList.fromObject(model)).toList();
    });
}


  Future<void> openCamera() async {
    // Ensure that plugin services are initialized so that `availableCameras()`
    // can be called before `runApp()`
    WidgetsFlutterBinding.ensureInitialized();

    /*if(firstCamera==null)
      {
        // Obtain a list of the available cameras on the device.
        final cameras = await availableCameras();

        // Get a specific camera from the list of available cameras.
        firstCamera = cameras.first;
      }
*/
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePictureScreen(
              deliveryID: deliveryID,
              driverEmail: widget.data,
              driverName: fullname,
              controller: widget.controller,
              initializeControllerFuture: widget.initializeControllerFuture,
            )
        )
    ).then((value) async {
      if(value.contains("Route Found!"))
      {
        _refreshPage();
      }
      else
      {
        showToastMessage(value);
      }
    });
  }

  Future<void> _refreshPage() async {
    // Perform any data fetching or updates here
    // You can update the state of the widget or fetch new data from a server

    // Simulating a delay for demonstration purposes
    await Future.delayed(Duration(seconds: 2));

    // Call setState to rebuild the UI with updated content
    setState(() {
      _restartPage(context);
    });
  }

  Future<void> deleteAllFiles() async
  {
    var appDocDir = await getExternalStorageDirectory();
    for (var file in appDocDir!.listSync()) {
      if (file is File) {
        file.delete();
      }
    }
  }

  void _restartPage(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(
          data: widget.data,
        controller: widget.controller,
        initializeControllerFuture: widget.initializeControllerFuture,
      )),
          (route) => false,
    );
  }

  @override
  void dispose() {
    //timer?.cancel();
    super.dispose();
  }

  void showToastMessage(String message)
  {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT, // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
      gravity: ToastGravity.BOTTOM, // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
      backgroundColor: Color(0XFF6b619d), // Background color of the toast
      textColor: Colors.white, // Text color of the toast
    );
  }

  Future<void> startJourney()
  async {
    if(_journeyStatus=="Start Journey")
    {
      if(truckNumber.trim().isEmpty || startingMileage.trim().isEmpty)
      {
        showToastMessage('Please Fill Both The Details!');
      }
      else if(!(int.tryParse(startingMileage) != null))
      {
        showToastMessage('Enter An Exact Number For Mileage!');
      }
      else
      {
        showDialog(
            context: context,
            builder:(BuildContext context) {
              return AlertDialog(
                backgroundColor: Color(0XFF6b619d),
                title: Text('TruckTrack',style: TextStyle(color: Colors.white),),
                content: Text("Are you sure you want to start the journey?",style: TextStyle(color: Colors.white),),
                actions: [
                  TextButton(
                    child: Text('No',style: TextStyle(color: Colors.white),),
                    onPressed: () {
                      Navigator.of(context).pop(false); // Close the dialog and return false
                    },
                  ),
                  TextButton(
                    child: Text('Yes',style: TextStyle(color: Colors.white),),
                    onPressed: ()  async {
                      if(isButtonEnabled){
                        isButtonEnabled = false;
                        await APIservices.postData('Master/updateDeliveryStatus?id=$deliveryID&status=Started');
                        await APIservices.postData('Master/updateInitialDeliveryDetails?deliveryID=$deliveryID&truckNumber=$truckNumber&mileage=$startingMileage&fuelTank=$dropdownvalue');
                        _refreshPage();
                      }
                    },
                  ),
                ],
              );
            });
      }
    }
    else if(_journeyStatus == "End Journey")
    {
      var dets = json.decode(deliveredDets);
      int count = 0;
      List<String> ids = [];
      for(int i=0;i<routesList.length;i++) {
        var id = custList
            .firstWhere((element) =>
        element.businessName == routesList[i] &&
            element.address1 == addressesList[i])
            .custId;
        ids.add(id.toString());
      }

      for(final det in dets)
      {
        if(ids.contains(det['customerID'].toString())  &&  deliveryID == det['deliveryID'])
          {
            count++;
          }
      }

      if(count==routesList.length)
        {
          showDialog(
              context: context,
              builder:(BuildContext context) {
                return AlertDialog(
                  backgroundColor: Color(0XFF6b619d),
                  title: Text('TruckTrack',style: TextStyle(color: Colors.white),),
                  content: Text("Are you sure you want to end the journey?",style: TextStyle(color: Colors.white),),
                  actions: [
                    TextButton(
                      child: Text('No',style: TextStyle(color: Colors.white),),
                      onPressed: () {
                        Navigator.of(context).pop(false); // Close the dialog and return false
                      },
                    ),
                    TextButton(
                      child: Text('Yes',style: TextStyle(color: Colors.white),),
                      onPressed: ()  {
                        if(isButtonEnabled){
                          isButtonEnabled = false;
                          APIservices.postData('Master/updateDeliveryStatus?id=$deliveryID&status=Ending Journey').then((value) {
                            _refreshPage();
                          });
                        }
                      },
                    ),
                  ],
                );
              });
        }
      else
        {
          showToastMessage("Please First Fill All Delivery Forms!");
        }
    }
    else
      {
        //_getLocation();
      }

  }


  void changeActive(int index)
  {
    mainRoutesList[index].bgColor = Colors.green;
    mainRoutesList[index].textColor = Colors.white;
    mainRoutesList[index].descColor = Colors.white;
    mainRoutesList[index].description = "[ Active ]";
    mainRoutesList[index].formStatus = "[   ]";
    mainRoutesList[index].formStatusColor = Colors.white;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () async{
         showDialog(
             context: context,
             builder:(BuildContext context) {
               return AlertDialog(
                 backgroundColor: Color(0XFF6b619d),
                 title: Text('TruckTrack',style: TextStyle(color: Colors.white),),
                 content: Text("Are you sure you want to log out?",style: TextStyle(color: Colors.white),),
                 actions: [
                   TextButton(
                     child: Text('No',style: TextStyle(color: Colors.white),),
                     onPressed: () {
                       Navigator.of(context).pop(false); // Close the dialog and return false
                     },
                   ),
                   TextButton(
                     child: Text('Yes',style: TextStyle(color: Colors.white),),
                     onPressed: () {
                       Navigator.pushAndRemoveUntil(
                         context,
                         MaterialPageRoute(builder: (context) => onBoardingScreen(
                           controller: widget.controller,
                           initializeControllerFuture: widget.initializeControllerFuture,
                         )),
                             (route) => false,
                       );
                     },
                   ),
                 ],
               );
             });
          return false;
        },
        child: RefreshIndicator(
            onRefresh: _refreshPage,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child:SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top:30.0,bottom:20.0,right:20.0,left:20.0),
                        child: Row(
                          children: [
                            Text("Hello ",
                              //style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.black, fontWeight: FontWeight.w600),
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 23,
                              ),
                            ),
                            Text(  fullname.contains(' ') ? fullname.split(' ')[0] : fullname,
                              //style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.black, fontWeight: FontWeight.w600),
                              style: GoogleFonts.poppins(
                                color: Color(0XFF4e4773),
                                fontWeight: FontWeight.w600,
                                fontSize: 23,
                              ),
                            ),
                            Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right:10.0),
                                child: GestureDetector(
                                  onTap: () async{
                                    await openCamera();
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0XFF6b619d),
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/Images/scan.png',
                                      fit: BoxFit.scaleDown,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: Color(0XFF6b619d),
                                          title: Text('TruckTrack',style: TextStyle(color: Colors.white),),
                                          content: Text("Are you sure you want to log out?",style: TextStyle(color: Colors.white),),
                                          actions: [
                                            TextButton(
                                              child: Text('No',style: TextStyle(color: Colors.white),),
                                              onPressed: () {
                                                Navigator.of(context).pop(false); // Close the dialog and return false
                                              },
                                            ),
                                            TextButton(
                                              child: Text('Yes',style: TextStyle(color: Colors.white),),
                                              onPressed: () {
                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => onBoardingScreen(
                                                    controller: widget.controller,
                                                    initializeControllerFuture: widget.initializeControllerFuture,
                                                  )),
                                                      (route) => false,
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0XFF6b619d),
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.exit_to_app, color: Colors.black,size: 27,),
                                  ),
                                ),
                              ),
                            ),
                            /* Lottie.asset(
                    'assets/LottieAssets/pulse2.json',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    ),*/
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:20.0,bottom:20.0,right:20.0,left:20.0),
                        child: Row(
                          children: [
                            Text("You're Here ",
                              //style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.black, fontWeight: FontWeight.w600),
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...forts.map((fort) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20, right:20, left:20),
                                  child: _isShimmering ?
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: FortCard(
                                      fort: fort,
                                      currentPosition:_currentPosition,
                                      currentAddress: "$_travellingTo",
                                      travellingTo: _currentAddress,
                                      address2Check: _address2Check,
                                      email: widget.data,
                                      fullName: fullname,
                                      getRoutesMethod: refresh,
                                      journeyStatus: _journeyStatus,
                                      startJourney: startJourney,
                                    ),
                                  ) : FortCard(
                                    fort: fort,
                                    currentPosition: _currentPosition,
                                    currentAddress: _currentAddress,
                                    travellingTo: _travellingTo,
                                    address2Check: _address2Check,
                                    email: widget.data,
                                    fullName: fullname,
                                    getRoutesMethod: refresh,
                                    journeyStatus: _journeyStatus,
                                    startJourney: startJourney,
                                  ),
                                )).toList(),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: start,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom:5, top: 10, right:20, left:26),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Truck Number:",
                                          style: TextStyle(
                                            color: Color(0XFF6a6589),
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: TextField(
                                            enabled: txtField1Enabled,
                                            controller: _controllerTruck,
                                            style: TextStyle(
                                              fontSize: 15,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                truckNumber = value;
                                              });
                                            },

                                          ),
                                        ),
                                        Text("|",
                                          style: TextStyle(
                                            color: Color(0XFF6a6589),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Starting Mileage:",
                                          style: TextStyle(
                                            color: Color(0XFF6a6589),
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: TextField(
                                            enabled: txtField2Enabled,
                                            controller: _controllerMileage,
                                            style: TextStyle(
                                              fontSize: 15,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                startingMileage = value;
                                              });
                                            },
                                          ),
                                        ),
                                        Text("|",
                                          style: TextStyle(
                                            color: Color(0XFF6a6589),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Fuel Tank:",
                                          style: TextStyle(
                                            color: Color(0XFF6a6589),
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: DropdownButton(
                                            value: dropdownvalue,
                                            underline: Container(
                                              height: 0,
                                            ),
                                            icon:const Icon(
                                              Icons.arrow_back_ios_new,
                                              size:1,
                                              color: Colors.white,
                                            ),
                                            items: items.map((String items) {
                                              return DropdownMenuItem(
                                                value: items,
                                                child: Text(
                                                  items,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) async {
                                              setState(() {
                                                dropdownvalue = newValue!;
                                              });
                                            },
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "Routes ($noOfRoutes)",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),),
                              ),
                              Column(
                                children: [
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              ...mainRoutesList.map((fort) =>
                                                  Padding(
                                                    padding: const EdgeInsets.only(left:25.0),
                                                    child:  Column(
                                                      children: [
                                                        Icon(
                                                          Icons.circle_rounded,
                                                          color: fort.textColor==Colors.white ? Colors.green : fort.textColor,
                                                          size: 17,
                                                        ),
                                                        mainRoutesList.last!=fort? Container(
                                                          width: 2.0,
                                                          height: 95,
                                                          color:  Color(0XFF4e4773),
                                                        ):Container(),
                                                      ],
                                                    ),
                                                  )
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                              child: Column(
                                                children: [
                                                  ...mainRoutesList.map((fort) =>
                                                      GestureDetector(
                                                        onTap: (){
                                                          if(fort.description.contains("Active"))
                                                          {
                                                            openGoogleMapsApp(fort.address);
                                                          }
                                                          else if(fort.description.contains("Delivered"))
                                                          {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (context) => FormScreen(
                                                                      cust: custList.firstWhere((x) => x.businessName==fort.title
                                                                          && x.address1 == fort.address),
                                                                      deliveredDets: deliveredDets,
                                                                      deliveryID: deliveryID,
                                                                    )
                                                                )
                                                            ).then((value) {
                                                              if(value.toString()=="Reload")
                                                              {
                                                                _refreshPage();
                                                                showToastMessage("The Form Has Been Submitted");
                                                              }
                                                            });
                                                          }
                                                        },
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(bottom: 20, right:20, left:20),
                                                          child: _isShimmering ? Shimmer.fromColors(
                                                            baseColor: Colors.grey[300]!,
                                                            highlightColor: Colors.grey[100]!,
                                                            child: SecondaryFortCart(fort: fort),
                                                          ) : SecondaryFortCart(fort: fort,),
                                                        ),
                                                      )),
                                                ],
                                              )
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          )
                      ),
                      Visibility(
                          visible: endJourney,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left:10.0),
                                child:  ExpansionPanelList(
                                  elevation: 0,
                                  // dividerColor: Colors.transparent,
                                  expansionCallback: (index, isExpanded) {
                                    setState(() {
                                      _isExpandedList[index] = !isExpanded;
                                    });
                                  },
                                  children: [
                                    ExpansionPanel(
                                      isExpanded: _isExpandedList[0],
                                      headerBuilder: (context, isExpanded) {
                                        return ListTile(
                                          title: Text('Mileage',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                      body: Padding(padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          child: Padding(padding: const EdgeInsets.only(left:8.0,right: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                            color: Color(0xFF37B085)),
                                                        children: <TextSpan>[
                                                          TextSpan(text: 'Starting Mileage',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0XFF6b619d))),
                                                          TextSpan(text: ' |',
                                                              style: TextStyle(
                                                                  color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        enabled: false,
                                                        controller: _startingMileage,
                                                        decoration: InputDecoration(
                                                          hintText: '',
                                                          border: InputBorder.none,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  height: 1,
                                                  color: Colors.grey,
                                                  width: double.infinity,
                                                ),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                            color: Color(0xFF37B085)),
                                                        children: <TextSpan>[
                                                          TextSpan(text: 'Ending Mileage',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0XFF6b619d))),
                                                          TextSpan(text: ' |',
                                                              style: TextStyle(
                                                                  color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: _endingMileage,
                                                        decoration: InputDecoration(
                                                          hintText: '',
                                                          border: InputBorder.none,
                                                        ),
                                                        onChanged: (value){
                                                          if(int.tryParse(value)!=null)
                                                          {
                                                            int start =  int.parse(_startingMileage.text.trim());
                                                            int end = int.parse(value.trim());
                                                            int result = end - start;
                                                            if(result>=0){
                                                              _distanceTravelled.text = result.toString();
                                                            }else{
                                                              _distanceTravelled.text = "";
                                                            }
                                                          }
                                                          else
                                                            {
                                                              _distanceTravelled.text = "";
                                                            }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  height: 1,
                                                  color: Colors.grey,
                                                  width: double.infinity,
                                                ),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                            color: Color(0xFF37B085)),
                                                        children: <TextSpan>[
                                                          TextSpan(text: 'Total Distance Traveled',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0XFF6b619d))),
                                                          TextSpan(text: ' |',
                                                              style: TextStyle(
                                                                  color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        enabled: false,
                                                        controller: _distanceTravelled,
                                                        decoration: InputDecoration(
                                                          hintText: '',
                                                          border: InputBorder.none,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0XFFFAF8F8),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ExpansionPanel(
                                      isExpanded: _isExpandedList[1],
                                      headerBuilder: (context, isExpanded) {
                                        return ListTile(
                                          title: Text('Fuel',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                      body: Padding(padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          child: Padding(padding: const EdgeInsets.only(left:8.0,right: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                            color: Color(0xFF37B085)),
                                                        children: <TextSpan>[
                                                          TextSpan(text: 'Starting Fuel Level',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0XFF6b619d))),
                                                          TextSpan(text: ' |',
                                                              style: TextStyle(
                                                                  color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        enabled: false,
                                                        controller: _startingFuel,
                                                        decoration: InputDecoration(
                                                          hintText: '',
                                                          border: InputBorder.none,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  height: 1,
                                                  color: Colors.grey,
                                                  width: double.infinity,
                                                ),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                            color: Color(0xFF37B085)),
                                                        children: <TextSpan>[
                                                          TextSpan(text: 'Ending Fuel Level',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0XFF6b619d))),
                                                          TextSpan(text: ' |',
                                                              style: TextStyle(
                                                                  color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: DropdownButton(
                                                        value: dropdownvalue_Final,
                                                        underline: Container(
                                                          height: 0,
                                                        ),
                                                        icon:const Icon(
                                                          Icons.arrow_back_ios_new,
                                                          size:1,
                                                          color: Colors.white,
                                                        ),
                                                        items: globalItems.map((String items) {
                                                          return DropdownMenuItem(
                                                            value: items,
                                                            child: Text(
                                                              items,
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (String? newValue) async {
                                                          setState(() {
                                                            dropdownvalue_Final = newValue!;
                                                            getFuelComp(dropdownvalue_Final);
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  height: 1,
                                                  color: Colors.grey,
                                                  width: double.infinity,
                                                ),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                            color: Color(0xFF37B085)),
                                                        children: <TextSpan>[
                                                          TextSpan(text: 'Fuel Consumption',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0XFF6b619d))),
                                                          TextSpan(text: ' |',
                                                              style: TextStyle(
                                                                  color: Colors.grey)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        enabled:false,
                                                        controller: _fuelConsumption,
                                                        decoration: InputDecoration(
                                                          hintText: '',
                                                          border: InputBorder.none,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0XFFFAF8F8),
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 170),
                                child: Center(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color(0xFFF6EBFF),
                                      padding: EdgeInsets.only(
                                          top: 15, left: 40, right: 40, bottom: 15),
                                    ),
                                    onPressed: () async {
                                      await submitForm();
                                    },
                                    child: Text(
                                        'Done', style: TextStyle(color: Color(0XFF6b619d))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      )
                    ],
                  ),
                ),
              ),
            )
        ),
      )
    );
  }

  Future<void> submitForm()
  async {
    if(_endingMileage.text.trim().isEmpty ||
        _distanceTravelled.text.trim().isEmpty ||
        dropdownvalue_Final.trim().isEmpty ||
        _fuelConsumption.text.trim().isEmpty)
    {
      showToastMessage('Please Fill All The Details!');
    }
    else
    {
      showDialog(
          context: context,
          builder:(BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0XFF6b619d),
              title: Text('TruckTrack',style: TextStyle(color: Colors.white),),
              content: Text("Are you sure you want to continue?",style: TextStyle(color: Colors.white),),
              actions: [
                TextButton(
                  child: Text('No',style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Close the dialog and return false
                  },
                ),
                TextButton(
                  child: Text('Yes',style: TextStyle(color: Colors.white),),
                  onPressed: ()  {
                    if(isButtonEnabled){
                      isButtonEnabled = false;
                      APIservices.postData('Master/updateFinalDeliveryDetails?deliveryID=$deliveryID&mileage=${_endingMileage.text}&fuelTank=$dropdownvalue_Final').then((value){
                        APIservices.postData('Master/updateDeliveryStatus?id=$deliveryID&status=Ended').then((value){
                          _refreshPage();
                        });
                      });
                    }
                  },
                ),
              ],
            );
          });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  void getFuelComp(String value)
  {
    String result ="";
    int? fuelResult = fuelMs[_startingFuel.text]! - fuelMs[value]!;
    for(final fuel in fuelMs.entries){
      if(fuel.value==fuelResult){
        result = fuel.key;
      }
    }
    _fuelConsumption.text = result;
  }


  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers

    double lat1Rad = degreesToRadians(lat1);
    double lon1Rad = degreesToRadians(lon1);
    double lat2Rad = degreesToRadians(lat2);
    double lon2Rad = degreesToRadians(lon2);

    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c;
    return distance;
  }

  double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  Future<List<double>> getCoordinates(String address) async {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isEmpty) {
      throw Exception('No results found for the address');
    }

    Location location = locations.first;
    return [location.latitude, location.longitude];


  }

  void _getLocation() async {
    setState(() {
      _controllerTruck.text = "Loading";
    });

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

  }


  Future<void> _getCurrentPosition(String email) async {

    final hasPermission = await _handleLocationPermission();
    var temp = _travellingTo;
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() => _currentPosition = position);
       await _getAddressFromLatLng(_currentPosition!);

      List<double> coordinates = await getCoordinates(_travellingTo!);
      double latitudeTo = coordinates[0];
      double longitudeTo = coordinates[1];

      double distance = calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        latitudeTo,
        longitudeTo,
      );
      bool isWithinRadius = distance <= 0.5;
      if(_travellingTo != 'No Pending Deliveries' && _journeyStatus=="Started"){
        if(isWithinRadius == true){
          postDelivery(email);;
        }
      }
    }).catchError((e) {
      //debugPrint(e.toString());
    });
    _travellingTo = temp;

    await APIservices.fetchData('Master/GetDeliveries').then((response) {
      Iterable list = json.decode(response.body);
      var listT = json.decode(response.body);
      List<DeliveriesList> deliveryList = List<DeliveriesList>.empty();
      deliveryList = list.map((model)=> DeliveriesList.fromObject(model)).toList();

      String itemStored="";

      if(deliveryID>=0){

        for(final item in listT){
          if(item['deliveryId'] == deliveryID){
            itemStored = item['invoices'].toString();
          }
        }

        try{
          var deliveryExists = deliveryList.firstWhere((x) => x.deliveryId==deliveryID &&
          x.routeAddresses == storeDelivery.routeAddresses && x.driverUserName == storeDelivery.driverUserName &&
          x.deliveryStatus == storeDelivery.deliveryStatus && x.deliveryDriver == storeDelivery.deliveryDriver &&
          x.deliveryRoutes == storeDelivery.deliveryRoutes && x.deliveryTimes == storeDelivery.deliveryTimes );

          if(deliveryFirst!=itemStored){
            _refreshPage();
          }
        }
        catch(e){
          _refreshPage().then((value){
            showToastMessage("The Routes Have Been Updated!");
          });
        }
       /* else{
          var del = deliveryList.firstWhere((element) => element.deliveryId == deliveryID);
          if(del.deliveryId!=storeDelivery.deliveryId ||
              del.deliveryRoutes!=storeDelivery.deliveryRoutes ||
              del.deliveryTimes!=storeDelivery.deliveryTimes ||
              del.deliveryDriver!=storeDelivery.deliveryDriver ||
              del.deliveryStatus!=storeDelivery.deliveryStatus ||
              del.driverUserName!=storeDelivery.driverUserName ||
              del.routeAddresses!=storeDelivery.routeAddresses || itemStored!=deliveryFirst){
            _refreshPage();
          }
        }*/
      }else if(deliveryList.firstWhere((element) => element.deliveryId != deliveryID && element.driverUserName==widget.data && element.deliveryStatus != "Ended")!=null) {
        _refreshPage().then((value){
          showToastMessage("The Routes Have Been Updated!");
        });
      }
    });
  }

  void openGoogleMapsApp(String address) async {
    String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address)}';

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  void startTimerAgain() {
    timer = Timer.periodic(Duration(seconds: 5), (_) {
      _getCurrentPosition(widget.data);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        '${place.street}, ${place.subLocality} , ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      //debugPrint(e);
    });
  }

  Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      //print('Error: $e');
    }
    return null;
  }

  void getAddressCoordinates() async {
    String? address = _currentAddress;
    LatLng? coordinates = await getLatLngFromAddress(address!);

    if (coordinates != null) {
      double latitude = coordinates.latitude;
      double longitude = coordinates.longitude;

    }
  }

  /*void publishCoordinates()
  async {
    if(_journeyStatus == "Started" )
      {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        DateTime now = DateTime.now();
        String formattedTime = DateFormat('H:mm').format(now);

        Workmanager().registerPeriodicTask(
          "taskOne",
          "Coordinates",
          frequency: F,
          inputData: <String,dynamic>{
            'id' : deliveryID,
            'latitude' : position.latitude,
            'longitude': position.longitude,
            'time' : formattedTime,
            'speed' : position.speed.toStringAsFixed(2)
          });
      }
  }*/

  Future<void> getDeliveryDets()
  async {
    await APIservices.fetchData('Master/GetDeliveryDetails?deliveryID=$deliveryID').then((response) {
      if(response.body.trim().isNotEmpty)
        {
          var dets = json.decode(response.body);
          setState(() {
            _controllerTruck.text = dets['truckNumber'];
            var mileage = dets['startingMileage'].toString();
            _controllerMileage.text = mileage;
            dropdownvalue = dets['fuelTank_Starting'];

            txtField1Enabled = false;
            txtField2Enabled = false;
            items = [dets['fuelTank_Starting']];
          });
        }
    });
  }

  Future<void> getPendingList(String comp) async{

    var completedList = comp.split(':').where((str) => str.isNotEmpty).toList();

    await APIservices.fetchData('Master/GetDeliveredDetails').then((response) {
      if(response.body.isNotEmpty)
      {
        deliveredDets = response.body;
        var dets = json.decode(response.body);
        for(final det in dets)
          {
            var name = custList.firstWhere((element) => element.custId==det['customerID']).businessName;
            if(completedList.contains(name))
            {
              if(det['deliveryID'].toString().trim() == deliveryID.toString() &&
                  (det['invoiceNo']!=null && det['invoiceNo'].toString().trim()!="" ) &&
                  (det['amountReceived']!=null && det['amountReceived'].toString().trim()!="") /*&&
                  (det['returnedItems']!=null && det['returnedItems'].toString().trim()!="")*/)
              {
                pending[name] = false;
              }
              else
                {
                  pending[name] = true;
                }
            }
          }
      }
    });
  }

  Future<void> getRouteData() async {
    _journeyStatus = "";
    await APIservices.fetchData('Master/GetDeliveries').then((response) {
      Iterable list = json.decode(response.body);
      var listT = json.decode(response.body);
      List<DeliveriesList> deliveryList = List<DeliveriesList>.empty();
      deliveryList = list.map((model)=> DeliveriesList.fromObject(model)).toList();

      String routes = '';
      String addresses = '';
      String completedRoutes ='';
      deliveryID = -1;

      try {
        deliveryID = deliveryList.firstWhere((element) => element.driverUserName==widget.data && element.deliveryStatus != "Ended").deliveryId;
        storeDelivery = deliveryList.firstWhere((element) => element.driverUserName==widget.data && element.deliveryStatus != "Ended");
        for(final item in listT){
          if(item['deliveryId']==deliveryID){
            deliveryFirst = item['invoices'].toString();
          }
        }
      }catch(e){

      }

      getDeliveryDets().then((value){
        deleteAllFiles();
        deliveryList.forEach((item) {
          if (item.deliveryStatus!="Ended") {
            if (item.driverUserName == widget.data) {
              _journeyStatus = item.deliveryStatus;
              if(_journeyStatus=="Ending Journey"){
                endJourney = true;
                setState(() {
                  _startingMileage.text = _controllerMileage.text;
                  _startingFuel.text = items[0];
                });
              }
              else
                {
                  start = true;
                }
              //publishCoordinates();
              if (item.deliveryTimes.isEmpty) {
                List<String> routesListA =
                item.deliveryRoutes.split(':').where((str) => str.isNotEmpty).toList();
                setState(()  {
                  //_travellingTo = routesListA[0];

                  APIservices.fetchData('Master/GetCustomers').then((response) async{

                    Iterable list = json.decode(response.body);
                    List<CustomersList> customerList = list.map((model) => CustomersList.fromObject(model)).toList();

                    customerList.forEach((item) {
                      if(item.businessName == routesListA.first)
                      {
                        if (item.address2 != '')
                        {
                          _travellingTo = '${item.address1}, ${item.address2}, ${item.city}, ${item.state}, ${item.zipCode}';
                          _address2Check = true;
                        }
                        else{
                          _travellingTo = '${item.address1}, ${item.city}, ${item.state}, ${item.zipCode}';
                          _address2Check = false;
                        }
                      }
                    });
                  });
                  setState(() {
                    routes = item.deliveryRoutes;
                    addresses = item.routeAddresses;
                  });
                });
              }
              else {
                List<String> routesListCompare =
                item.deliveryRoutes.split(':').where((str) => str.isNotEmpty).toList();
                List<String> completedList = item.deliveryTimes.split(':').where((str) => str.isNotEmpty).toList();

                routesListCompare.removeWhere((value) => completedList.contains(value));

                if(routesListCompare.length > 0 )
                {
                  //_travellingTo = routesListCompare.first;
                  APIservices.fetchData('Master/GetCustomers').then((response) {

                    Iterable list = json.decode(response.body);
                    List<CustomersList> customerList = List<CustomersList>.empty();
                    customerList = list.map((model) => CustomersList.fromObject(model)).toList();


                    customerList.forEach((item) {
                      if(item.businessName == routesListCompare.first)
                      {
                        if (item.address2 != '')
                        {
                          setState(() {
                            _travellingTo = '${item.address1}, ${item.address2}, ${item.city}, ${item.state}, ${item.zipCode}';

                          });
                        }
                        else{
                          setState(() {
                            _travellingTo = '${item.address1}, ${item.city}, ${item.state}, ${item.zipCode}';
                          });
                        }
                      }

                    });
                  });
                }
                setState(() {
                  routes = item.deliveryRoutes;
                  addresses = item.routeAddresses;
                  completedRoutes = item.deliveryTimes;
                });
              }
            }
          }
        });
        getPendingList(completedRoutes).then((value){
          routesList = routes.split(':').where((str) => str.isNotEmpty).toList();
          addressesList = addresses.split(':').where((str) => str.isNotEmpty).toList();
          completedListB = completedRoutes.split(':').where((str) => str.isNotEmpty).toList();

          int count = 0;
          int completedIndex = 0;
          routesList.asMap().forEach((index,item) async {
            noOfRoutes = routesList.length;
            if(completedListB.contains(item)) {
              if(pending.containsKey(item) && pending[item]==false)
              {
                setState(() {
                  mainRoutesList.add(
                    Fort(title: item,
                      address: addressesList[count],
                      textColor: Colors.grey,
                      bgColor: Color(0XFFf7f5ff),
                      iconSrc: Icons.done_rounded,
                      iconClr: Color(0xFF37B085),
                      divColor: Colors.grey,
                      description: "[ Delivered ]",
                      descColor: Colors.black,
                      formStatus: "[ ✓ ]",
                      formStatusColor: Colors.black,
                    ),
                  );
                });
              }
              else{
                setState(() {
                  mainRoutesList.add(
                    Fort(title: item,
                      address: addressesList[count],
                      textColor: Colors.grey,
                      bgColor: Color(0XFFf7f5ff),
                      iconSrc: Icons.done_rounded,
                      iconClr: Color(0xFF37B085),
                      divColor: Colors.grey,
                      description: "[ Delivered ]",
                      descColor: Colors.black,
                      formStatus: "[ O ]",
                      formStatusColor: Colors.black,
                    ),
                  );
                });
              }
              completedIndex = index;
              completedListB.remove(item);
            }
            else if(!completedListB.isEmpty && index == completedIndex + 1) {
              setState(() {
                mainRoutesList.add(
                  Fort(title: item),
                );
                mainRoutesList[mainRoutesList.length-1].address = addressesList[count];
              });
            }
            else if(index == 0) {
              setState(() {
                mainRoutesList.add(
                  Fort(title: item),
                );
                mainRoutesList[mainRoutesList.length-1].address = addressesList[count];
              });
            }
            else
            {
              setState(() {
                mainRoutesList.add(
                  Fort(title: item,
                      address: addressesList[count],
                      textColor: const Color(0XFF4e4773),
                      bgColor: Color(0XFFf7f5ff),
                      iconSrc: Icons.incomplete_circle_rounded,
                      iconClr: Color(0xFF37B085),
                      divColor: Color(0xFF37B085),
                      description: "[ Pending ]",
                      descColor: Colors.black),
                );
              });
            }
            count++;
          });
          setState(() {
            if(mainRoutesList.where((x) => (x.description.contains("Delivered"))).toList().isNotEmpty)
            {
              var routes = mainRoutesList.where((x) => (x.description.contains("Delivered"))).toList();
              int index = mainRoutesList.indexOf(routes.last);
              if(index<mainRoutesList.length-1)
              {
                changeActive(index+1);
              }
            }else if(_journeyStatus=="Started")
            {
              changeActive(0);
            }

          });
        });
      });

      // String routes = "nope";
      // for (var item in deliveryList) {
      //   if (item.driverUsername == widget.data) {
      //     routes = item.deliveryRoutes;
      //     break; // Optional: If you only need the first matching item
      //   }
      // }

      // setState(() {
      //   _currentAddress = routes; // Update the state with the filtered result
      // });
    });
  }

  bool isFormPending(String name, String address)  {
    bool pending = true;

      APIservices.fetchData('Master/GetCustomers').then((response) async {
      Iterable list = json.decode(response.body);
      List<CustomersList> customerList = list.map((model) => CustomersList.fromObject(model)).toList();
      int custID = customerList.firstWhere((element) => element.businessName == name && element.address1 == address).custId;
      await APIservices.fetchData('Master/GetExactDeliveredDetails?deliveryID=$deliveryID&customerID=$custID').then((response) {
        if(response.body.isNotEmpty)
          {
            var dets = json.decode(response.body);

            if((dets['invoiceNo']!=null && dets['invoiceNo'].toString().trim()!="" ) &&
                (dets['amountReceived']!=null && dets['amountReceived'].toString().trim()!="") &&
                (dets['returnedItems']!=null && dets['returnedItems'].toString().trim()!=""))
            {
              pending = false;
            }
          }
      });
    });
    return pending;
  }

  void getUserData(String email) async {
    var response = await APIservices.fetchData('Master/GetUsers');

    Iterable list = json.decode(response.body);
    List<Users> userList = list.map((model) => Users.fromObject(model)).toList();

    for (var item in userList) {
      if (item.userName == email) {
        setState(() {
          fullname = item.fullName;
        });
      }
    }
  }

  postDelivery(String email) async {
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('H:mm').format(now);

    final response = await APIservices.postData('Master/PostDeliveryTime?UserName=$email&time=$formattedTime');

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => EntryPoint(
                data: email,
              controller: widget.controller,
              initializeControllerFuture: widget.initializeControllerFuture,
            )));
  }
}

class SecondaryFortCart extends StatelessWidget {
  const SecondaryFortCart({
    super.key, required this.fort,
  });

  final Fort fort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color:fort.bgColor,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fort.title.length > 17 ? fort.title.substring(0, 17) + '...' : fort.title,
                  style:GoogleFonts.poppins(
                    color: fort.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Text("Address: ",
                      style: TextStyle(
                        fontSize: 12,
                        color: fort.descColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(fort.address.length > 17 ? fort.address.substring(0, 17) + '...' : fort.address,
                      style: TextStyle(
                          fontSize: 12,
                          color: fort.descColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Status: ",
                      style: TextStyle(
                        fontSize: 12,
                        color: fort.descColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Row(
                      children: [
                        Text(fort.description,
                          style: TextStyle(
                              fontSize: 12,
                              color: fort.descColor),
                        ),
                        fort.formStatus=="[ O ]"? Row(
                          children: [
                            Text(" [",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: fort.descColor),
                            ),
                            Text(" Form Pending ",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green),
                            ),
                            Text("]",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: fort.descColor),
                            ),
                          ],
                        ):Row(),
                      ],
                    ),
                    const Spacer(),
                    Text(fort.formStatus,
                      style: TextStyle(
                          fontSize: 12,
                          color: fort.formStatusColor),
                    ),
                  ],
                )
              ],
            ),
          ),
          /*SizedBox(
            height: 40,
            child: VerticalDivider(
              color: fort.divColor,
            ),
          ),
          SizedBox(width:8),
          Icon(
            fort.iconSrc,
            color: fort.iconClr,
          ),*/
        ],
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.deliveryID,
    required this.driverEmail,
    required this.driverName, this.controller,
    required this.initializeControllerFuture,
  });

  final CameraController? controller;
  final Future<void> initializeControllerFuture;
  final int deliveryID;
  final String driverName;
  final String driverEmail;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    /*_controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.ultraHigh,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller!.initialize();*/
    _controller = widget.controller;
    _initializeControllerFuture = widget.initializeControllerFuture;
  }

  static Future<XFile?> captureImageInIsolate(CameraController controller) async {
    try {
      return await controller.takePicture();
    } catch (e) {
      print('Error capturing image in isolate: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    //_controller?.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async{
          //dispose();
          Navigator.pop(context,null);
          return true;
        },
        child: Theme(
            data: ThemeData(
                primaryColor: Colors.white,
                appBarTheme: AppBarTheme(
                  iconTheme: IconThemeData(
                    color: Colors.black,
                  ),
                  color: Colors.white,
                  titleTextStyle: GoogleFonts.poppins(
                    color: Color(0XFF4e4773),
                    fontWeight: FontWeight.w600,
                    fontSize:19,
                  ),
                ),
            ),
            child: Container(
              color: Colors.white,
              child: isLoading
                  ?  DefaultTextStyle(
                  style: GoogleFonts.poppins(
                  color: Color(0XFF6b619d),
                  fontWeight: FontWeight.w200,
                  fontSize: 15,
                   ),
                  child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0XFF4e4773),
                          ),
                          SizedBox(height: 20,),
                          Container(
                            width: 300,

                            child: Center(
                              child: Text("Kindly Hold The Camera Still",
                                softWrap: true,
                                style: GoogleFonts.poppins(
                                  color: Color(0XFF6b619d),
                                  fontWeight: FontWeight.w200,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                  )) :
              Scaffold(
                appBar: AppBar(title: const Text('Capture Invoice')),
                // You must wait until the controller is initialized before displaying the
                // camera preview. Use a FutureBuilder to display a loading spinner until the
                // controller has finished initializing.
                body: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the Future is complete, display the preview.
                      return CameraPreview(_controller!);
                    } else {
                      // Otherwise, display a loading indicator.
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  // Provide an onPressed callback.
                  onPressed: () async {
                    // Take the Picture in a try / catch block. If anything goes wrong,
                    // catch the error.
                    await _initializeControllerFuture.then((value) async {
                      if(_controller==null || !_controller!.value.isInitialized){
                        return;
                      }
                      try {
                        // Ensure that the camera is initialized.
                        setState(() {
                          isLoading = true;
                        });
                        // Attempt to take a picture and get the file `image`
                        // where it was saved.
                        Future.delayed(Duration.zero, () async {

                          final value = await _controller!.takePicture();
                          String result = "";

                          var appDocDir = await getExternalStorageDirectory();
                          if(value!=null && widget.deliveryID!=null)
                          {
                            XFile image = value;
                            File file = File('${appDocDir?.path}/${image.name}');
                            await file.writeAsBytes(File(image.path).readAsBytesSync());

                            var imageBase64 = base64Encode(File('${appDocDir?.path}/${image.name}').readAsBytesSync());

                            ImageInput imageInput = ImageInput(imageBase64, widget.deliveryID,widget.driverEmail,widget.driverName);

                            await APIservices.postDataToApi('Master/GetBusinessOcr', imageInput).then((response) async {
                              result = response!.body;
                              /*if(result.contains("Route Found!"))
                              {
                                await APIservices.postDataToApi('Master/UploadAndSaveImage', imageInput);
                              }*/
                            });

                            try
                            {
                              await for (var file in appDocDir!.list()) {
                                if (file is File) {
                                  await file.delete();
                                }
                              }
                              print("Success");
                            }
                            catch(e)
                            {
                              print("Fail : $e");
                            }
                          }

                          setState(() {
                            isLoading = false;
                          });

                          Navigator.pop(context,result);
                        });


                      } catch (e) {
                        // If an error occurs, log the error to the console.
                        setState(() {
                          isLoading = false;
                        });
                        //print(e);
                      }
                    });

                  },
                  child: const Icon(Icons.camera_alt),
                ),
              ),
            )
        ),
        );
  }
}