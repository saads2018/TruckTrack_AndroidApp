import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/api.services.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final IPController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    IPController.text = APIservices.baseURL;
  }

  void collapseKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  Future<void> writeDataToFile(String data,String fileName) async {
    final file = File('${(await getApplicationDocumentsDirectory()).path}/$fileName.txt');
    await file.writeAsString(data);
  }

  @override
  Widget build(BuildContext context) {
    int colorCode = 0XFF6b619d;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Manage API',
              style:GoogleFonts.poppins(
                color: Color(colorCode),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
        TextFormField(
          controller: IPController,
          decoration: InputDecoration(
            labelText: 'IP Address',
          ),
        ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                  onPressed: (){
                    IPController.text = APIservices.origBaseURL;
                    collapseKeyboard(context);
                    Fluttertoast.showToast(
                      msg: 'IP Address Reset',
                      toastLength: Toast.LENGTH_SHORT, // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
                      gravity: ToastGravity.BOTTOM, // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
                      backgroundColor: Color(0XFF6b619d), // Background color of the toast
                      textColor: Colors.white, // Text color of the toast
                    );
                  }, child: Text("Reset",style:TextStyle(
                    fontWeight: FontWeight.w600,
                  ),)
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: (){
                        if(IPController.text.endsWith('/') != true)
                        {
                          IPController.text = '${IPController.text}/';
                        }
                        APIservices.saveBaseURL(IPController.text);
                        writeDataToFile(IPController.text, "ip");
                        collapseKeyboard(context);
                        Fluttertoast.showToast(
                          msg: 'IP Address Saved',
                          toastLength: Toast.LENGTH_SHORT, // Duration: Toast.LENGTH_SHORT or Toast.LENGTH_LONG
                          gravity: ToastGravity.BOTTOM, // Position: ToastGravity.TOP, ToastGravity.CENTER or ToastGravity.BOTTOM
                          backgroundColor: Color(0XFF6b619d), // Background color of the toast
                          textColor: Colors.white, // Text color of the toast
                        );
                      }, child: Text("Save",style:TextStyle(
                      fontWeight: FontWeight.w600,
                    ),),
                    ),
                  ),
              ],
            )

          ],
        ),
      ),
    );
  }
}
