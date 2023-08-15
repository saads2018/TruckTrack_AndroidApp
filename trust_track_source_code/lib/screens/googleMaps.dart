import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleMaps extends StatefulWidget {
  const GoogleMaps({Key? key, required this.location, required this.addressCheck}) : super(key: key);

  final String? location;
  final bool addressCheck;

  @override
  State<GoogleMaps> createState() => _GoogleMapsState();

}


class _GoogleMapsState extends State<GoogleMaps> {
  late List<String> locationAddress;
  late String address1;
  late String address2;
  late String state;
  late String city;
  late String zipCode;

  @override
  void initState() {
    super.initState();
    List<String>? locationAddress = widget.location?.split(', ').where((str) => str.isNotEmpty).toList();

    if(widget.addressCheck == true)
    {
      address1 = locationAddress![0];
      address2 = locationAddress[1];
      state = locationAddress[2];
      city = locationAddress[3];
      zipCode = locationAddress[4];
    }
    else
    {
      address1 = locationAddress![0];
      state = locationAddress[1];
      city = locationAddress[2];
      zipCode = locationAddress[3];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.toString()),
      ),
      body: WebView(
        initialUrl: "https://www.google.com/maps/place/$address1+$state+$city,+$zipCode",
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
