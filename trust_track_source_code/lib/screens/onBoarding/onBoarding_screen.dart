
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/api.services.dart';
import '../../utilis/entry_point.dart';
import '../settings/settings_screen.dart';

class onBoardingScreen extends StatefulWidget {
  const onBoardingScreen({Key? key, this.controller, required this.initializeControllerFuture}) : super(key: key);

  final CameraController? controller;
  final Future<void> initializeControllerFuture;
  @override
  State<onBoardingScreen> createState() => _onBoardingScreenState();
}

class _onBoardingScreenState extends State<onBoardingScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final textFieldKey = GlobalKey<FormState>();
  double containerHeight = 427.0; //Original: 427
  bool isSignInDialogShown = false;
  String fullName='';
  int colorCode = 0XFF6b619d;

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

  @override
  void initState() {
    super.initState();
    _handleLocationPermission();
    emailController.text = APIservices.savedUsername;
    passwordController.text = APIservices.savedPassword;
  }

  Future<void> writeDataToFile(String data,String fileName) async {
    final file = File('${(await getApplicationDocumentsDirectory()).path}/$fileName.txt');
    await file.writeAsString(data);
  }

  // void getUserData(String email) async {
  //   var response = await APIservices.fetchData('Master/GetUsers');
  //   print(response.statusCode);
  //   print(response.body);
  //   Iterable list = json.decode(response.body);
  //   List<Users> userList = list.map((model) => Users.fromObject(model)).toList();
  //
  //   for (var item in userList) {
  //     if (item.userName == email) {
  //       setState(() {
  //         fullName = item.fullName;
  //       });
  //     }
  //   }
  // }





  Future<bool> checkUserValidation(String username, String password) async {
    //final response = await APIservices.postData('Master/CheckIfUserIsValid?Email=stanleyhopps6512@gmail.com&Password=newYears99@g');
    final response = await APIservices.fetchData('Master/CheckIfUserIsValid?Email=$username&Password=$password');
    final responseUsers = await APIservices.fetchData('Master/GetUsers');
    var listT = json.decode(responseUsers.body);
    if (response.body.toString() == 'true') {
      bool exists = false;
      for(final item in listT){
        if(item['email'].toString() == username.toString() && item['driver'].toString() == "true"){
          exists = true;
        }
      }
      return exists; // User validation successful
    } else {
      return false; // User validation failed
    }
  }

  postBiometricData(String username, String password) async {
    final response = await APIservices.postData('Master/CheckIfUserIsValid?Email=stanleyhopps6512@gmail.com&Password=newYears99@g');
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true; // Internet is available
    } else {
      return false; // No internet connection
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Stack(
        children: [
          AnimatedPositioned(
            top: isSignInDialogShown ? -50 : 0,
            duration: Duration(milliseconds: 240),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: GestureDetector(
                          onTap: ()
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Settings()),
                            );
                          },
                          child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Image.asset("assets/Images/truckAltLogoW.png",width: 67,height: 67,),
                    ),
                        )),
                    //Spacer(),
                    SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          Text(
                            'Truck Track & Report',
                            style: GoogleFonts.poppins(
                              fontSize: 60,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height:16),
                          Text(
                            "Track your progress, make deliveries and report back while getting exact directions and updates on your assigned routes.",
                            style: TextStyle(
                              color: Colors.white,
                            )
                            ,)
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      height: 64,
                      width: 260,
                      child: Stack(
                        children: [
                          // RiveAnimation.asset(
                          //     "assets/RiveAssets/buttonA.riv"
                          // ),
                          Positioned.fill(
                            top: 8,
                            child:ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isSignInDialogShown = true;
                                });
                                showGeneralDialog(
                                  barrierDismissible: true,
                                  barrierLabel: "Sign In",
                                  context: context,
                                  transitionDuration: Duration(milliseconds: 400),
                                  transitionBuilder: (context, animation, secondaryAnimation, child){
                                    Tween<Offset> tween;
                                    tween = Tween(begin: Offset(0,-1), end:Offset.zero);
                                    return SlideTransition(position: tween.animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                    ),
                                      child: child,
                                    );
                                  },
                                  pageBuilder: (context, _, __) => Center(
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 400),
                                      height: 365.0,
                                      margin: EdgeInsets.symmetric(horizontal: 16),
                                      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.99),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(40),
                                        ),
                                      ),
                                      child:Scaffold(
                                        resizeToAvoidBottomInset:false,
                                        backgroundColor: Colors.transparent,
                                          body: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              SingleChildScrollView(
                                                child: Column(
                                                    children: [
                                                      Text(
                                                        "Sign In",
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 34,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 0), //Original:16
                                                        child: Text("",
                                                          textAlign: TextAlign.center,),
                                                      ),
                                                      Form(
                                                          key:textFieldKey,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                "Email",style: TextStyle(
                                                                  color: Colors.black54
                                                              ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.only(top:8.0,bottom: 16),
                                                                child: TextFormField(
                                                                  controller: emailController,
                                                                  decoration: InputDecoration(
                                                                  prefixIcon: Icon(
                                                                    Icons.email,color: Color(colorCode),
                                                                  ),
                                                                ),
                                                                  validator: (value){
                                                                    if(value!.isEmpty){
                                                                      return "";
                                                                    }
                                                                    return null;
                                                                  },
                                                                  onSaved: (email){},
                                                                ),
                                                              ),
                                                              Text(
                                                                "Password",style: TextStyle(
                                                                  color: Colors.black54
                                                              ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.only(top:8.0,bottom: 16),
                                                                child: TextFormField(
                                                                  controller: passwordController,
                                                                  obscureText: true,
                                                                  decoration: InputDecoration(
                                                                    prefixIcon: Icon(Icons.lock,color: Color(colorCode),
                                                                    ),
                                                                  ),
                                                                  validator: (value){
                                                                    if(value!.isEmpty){
                                                                      return "";
                                                                    }
                                                                    return null;
                                                                  },
                                                                  onSaved: (password){},
                                                                ),
                                                              ),
                                                              ElevatedButton.icon(
                                                                onPressed: (){
                                                                  if(textFieldKey.currentState!.validate())
                                                                  {
                                                                  checkInternetConnectivity().then((value) async {
                                                                    if (value == true) {

                                                                      await APIservices.checkConnectionToIP().then((value){
                                                                        if(value == true){

                                                                          checkUserValidation(emailController.text, passwordController.text).then((isValid) {
                                                                            if (isValid == true) {
                                                                              Navigator.pushAndRemoveUntil(
                                                                                context,
                                                                                MaterialPageRoute(builder: (context) => EntryPoint(
                                                                                    data: emailController.text,
                                                                                  controller: widget.controller,
                                                                                  initializeControllerFuture: widget.initializeControllerFuture,
                                                                                )),
                                                                                    (route) => false,
                                                                              );
                                                                              APIservices.saveUsername(emailController.text);
                                                                              APIservices.savePassword(passwordController.text);
                                                                              writeDataToFile(emailController.text, "email");
                                                                            }
                                                                            else {
                                                                              Fluttertoast
                                                                                  .showToast(
                                                                                msg: 'Invalid Email or Password',
                                                                                toastLength: Toast
                                                                                    .LENGTH_SHORT,
                                                                                // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
                                                                                gravity: ToastGravity
                                                                                    .BOTTOM,
                                                                                // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
                                                                                backgroundColor: Colors
                                                                                    .white,
                                                                                // Background color of the toast
                                                                                textColor: Colors
                                                                                    .black, // Text color of the toast
                                                                              );
                                                                            }
                                                                          },
                                                                          );
                                                                        }
                                                                        else
                                                                        {
                                                                          Fluttertoast
                                                                              .showToast(
                                                                            msg: "Can't Connect to Server",
                                                                            toastLength: Toast
                                                                                .LENGTH_SHORT,
                                                                            // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
                                                                            gravity: ToastGravity
                                                                                .BOTTOM,
                                                                            // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
                                                                            backgroundColor: Colors
                                                                                .white,
                                                                            // Background color of the toast
                                                                            textColor: Colors
                                                                                .black, // Text color of the toast
                                                                          );
                                                                        }
                                                                      });
                                                                    }
                                                                    else {
                                                                      Fluttertoast
                                                                          .showToast(
                                                                        msg: 'Please Connect to Wifi',
                                                                        toastLength: Toast
                                                                            .LENGTH_SHORT,
                                                                        // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
                                                                        gravity: ToastGravity
                                                                            .BOTTOM,
                                                                        // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
                                                                        backgroundColor: Colors
                                                                            .white,
                                                                        // Background color of the toast
                                                                        textColor: Colors
                                                                            .black,
                                                                      );
                                                                    }
                                                                  });
                                                                  }
                                                                  else
                                                                  {
                                                                    Fluttertoast.showToast(
                                                                      msg: 'Fill in all the Fields',
                                                                      toastLength: Toast.LENGTH_SHORT, // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
                                                                      gravity: ToastGravity.BOTTOM, // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
                                                                      backgroundColor: Colors.white, // Background color of the toast
                                                                      textColor: Colors.black, // Text color of the toast
                                                                    );
                                                                  }
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  minimumSize: Size(double.infinity,56),
                                                                  shape:RoundedRectangleBorder(borderRadius: BorderRadius.only(
                                                                    topLeft: Radius.circular(10),
                                                                    topRight: Radius.circular(25),
                                                                    bottomLeft: Radius.circular(25),
                                                                    bottomRight: Radius.circular(25),
                                                                  ),
                                                                  ),
                                                                ),
                                                                icon: Icon(Icons.arrow_right, color: Colors.white,),
                                                                label: Text("Sign In"),
                                                              ),
                                                            ],
                                                          )
                                                      ),
                                                    ],
                                                  ),
                                              ),
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: -50, //Original: -48
                                                child: CircleAvatar(
                                                  radius: 16, backgroundColor:Colors.white,
                                                  child:Icon(
                                                    Icons.close,
                                                    color:Color(colorCode),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ).then((_){
                                  setState(() {
                                    isSignInDialogShown = false;
                                  });
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Color(colorCode),
                                backgroundColor: Colors.white, // Set the button text color
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12), // Set the button padding
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50), // Set the button border radius
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_right,
                                    color: Color(colorCode), // Set the icon color
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Continue Tracking",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(colorCode),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // child: Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     Icon(Icons.arrow_right,
                            //       color: Colors.white,
                            //     ),
                            //     SizedBox(width: 8),
                            //     Text(
                            //         "Continue Trucking",
                            //         style:TextStyle(
                            //           fontWeight: FontWeight.w600,
                            //         color: Colors.white,
                            //         ),
                            //     ),
                            //   ],
                            // ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Please do not use this app while driving, keep your eyes on the road at all times, only use the app while stationary.",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

      ),
    );
  }
}