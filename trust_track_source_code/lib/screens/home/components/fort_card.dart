import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../models/fort.dart';
import 'package:intl/intl.dart';

  class FortCard extends StatelessWidget {
   FortCard({
    super.key, required this.fort, required this.currentPosition, this.currentAddress, this.travellingTo, required this.address2Check,
     required this.email, required this.getRoutesMethod, required this.fullName, required this.journeyStatus, required this.startJourney
  });

  final Fort fort;
  final Function startJourney;
  final Position? currentPosition;
  final String? currentAddress;
  final String? travellingTo;
  final String email;
  final bool address2Check;
  final VoidCallback getRoutesMethod;
  final String fullName;
  String? journeyStatus;
  Color colorCode_Status = Color(0XFF24c035);

   void openGoogleMapsApp(String address) async {
     String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address)}';

     if (await canLaunchUrlString(googleMapsUrl)) {
       await launchUrlString(googleMapsUrl);
     } else {
       throw 'Could not launch $googleMapsUrl';
     }
   }

  //  postDelivery(String email) async {
  //   DateTime now = DateTime.now();
  //   String formattedTime = DateFormat('H:mm').format(now);
  //
  //   final response = await APIservices.postData('Master/PostDeliveryTime?UserName=$email&time=$formattedTime');
  //   print(response.body);
  // }


  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidthPercentage = 0.90; // 90% of the screen width
    double containerWidth = screenWidth * containerWidthPercentage;

    if(journeyStatus =="End Journey") {
        colorCode_Status = Colors.red;
      }
    else if(journeyStatus =="Ending Journey"){
      colorCode_Status = const Color(0XFF6a6589);
    }

    String addresss = "";
    if(currentPosition!=null && currentAddress!=null)
      {
        if( currentAddress!.length>15)
          {
            addresss = "${currentAddress?.substring(0,15)}...";
          }else{
          addresss = "$currentAddress";
        }
      }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical:20),
      width: containerWidth,
      height: 100,
      decoration: BoxDecoration(
        color: Color(0XFFf7f5ff),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.all(
          color: Color(0XFFdce3ef),
          width: 2.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fort.title,
                  style:GoogleFonts.poppins(
                    color: Color(0XFF4e4773),
                    fontWeight: FontWeight.w600,
                    fontSize:16,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 1.0),
                  child: Row(
                    children: [
                      const Text('Address:  \n',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text('${addresss}\n',
                      //Latitude: ${currentPosition!.latitude}, Longitude: ${currentPosition!.longitude}'
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize:14,
                        ),
                      ),
                    ],
                  )
                ),
                // Padding(
                //   padding: const EdgeInsets.only(top:12, bottom:8),
                //   child: Text(fort.description,
                //     style: TextStyle(
                //         color: Colors.white70),
                //   ),
                // ),
                // Text("61 SECTIONS - 11 HOURS",
                //   style: TextStyle(
                //       color: Colors.white54),
                // ),
                // Spacer(),
                // Row(children: [
                //   ...List.generate(3,
                //         (index) => Transform.translate(
                //       offset: Offset((-10 * index).toDouble(),0),
                //       child: CircleAvatar(
                //         radius:20,
                //         backgroundImage: AssetImage(
                //             "assets/Images/person${index+1}.jpg"),
                //       ),
                //     ),
                //   ),
                // ],
                // ),
              ],
            ),
          ),
        //  Icon(fort.iconSrc, color: Colors.white,),
          Padding(padding: const EdgeInsets.only(top:4),
            child: GestureDetector(
              onTap: () async {
                await startJourney();
              },
            child: Text('${journeyStatus}',
              style: TextStyle(
                color: colorCode_Status,
                fontWeight: FontWeight.w600,
                fontSize:14,
              ),
            ),
            )
            )
        ],
      ),
    );
  }
}