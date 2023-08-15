import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/api.services.dart';
import '../../../models/customersList.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({Key? key,required this.cust,required this.deliveredDets,required this.deliveryID}) : super(key: key);
  final CustomersList cust;
  final String deliveredDets;
  final int deliveryID;

  @override
  State<FormScreen> createState() => _FormState();
}

class _FormState extends State<FormScreen> {
  List<bool> _isExpandedList = [false, false, false];
  TextEditingController _invoice = TextEditingController(text: "");
  TextEditingController _cash = TextEditingController(text: "");
  TextEditingController _cheque = TextEditingController(text: "");
  TextEditingController _account = TextEditingController(text: "");
  TextEditingController _returnedItems = TextEditingController(text: "");
  bool _exists = false;

  @override
  void initState() {
    if(widget.deliveredDets.trim().isNotEmpty)
      {
        var dets = json.decode(widget.deliveredDets);
        for(final det in dets)
          {
            if(widget.cust.custId==det['customerID'] && widget.deliveryID==det['deliveryID'])
              {
                setState(() {
                  _exists = true;

                  if( det['invoiceNo']!=null)
                    {
                      _invoice.text = det['invoiceNo'].toString();
                    }

                  if(det['amountReceived'].toString().contains("Cash"))
                    {
                      _cash.text = det['amountReceived'].toString().substring(det['amountReceived'].toString().indexOf(":")+1);
                    }
                  else if(det['amountReceived'].toString().contains("Cheque"))
                  {
                    _cheque.text = det['amountReceived'].toString().substring(det['amountReceived'].toString().indexOf(":")+1);
                  }
                  else  if(det['amountReceived'].toString().contains("Account"))
                  {
                    _account.text = det['amountReceived'].toString().substring(det['amountReceived'].toString().indexOf(":")+1);
                  }
                  if( det['returnedItems']!=null) {
                    _returnedItems.text = det['returnedItems'].toString();
                  }
                });
              }
          }
      }
  }


  Future<void> submitForm()
  async {
    if(_invoice.text.trim().isEmpty || (_cash.text.trim().isEmpty && _cheque.text.trim().isEmpty && _account.text.trim().isEmpty))
    {
      showToastMessage('Please Fill The First Two Details!');
    }
    else if(!(int.tryParse(_invoice.text.trim()) != null))
    {
      showToastMessage('Enter A Number For The Invoice Field!');
    }
    else
    {
      var amount = "";
      var done = 0;
      if(_cash.text.trim().isNotEmpty)
        {
          amount = "Cash:"+_cash.text.trim();
          done++;
        }
      if(_cheque.text.trim().isNotEmpty)
      {
        amount = "Cheque:"+_cheque.text.trim();
        done++;
      }
      if(_account.text.trim().isNotEmpty)
      {
        amount = "Account:"+_account.text.trim();
        done++;
      }
      if(done==1)
        {
          if(!_returnedItems.text.trim().isNotEmpty)
            {
              _returnedItems.text="None";
            }
          if(_exists) {
            await APIservices.postData(
                'Master/updateDeliveredDetails?deliveryID=${widget
                    .deliveryID}&customerID=${widget.cust
                    .custId}&invoice=${_invoice
                    .text}&returnedItems=${_returnedItems.text}&amount=$amount')
                .then((value) {
              Navigator.pop(context, "Reload");
            });
          }
          else
            {
              await APIservices.postData(
                  'Master/addDeliveredDetails?deliveryID=${widget
                      .deliveryID}&customerID=${widget.cust
                      .custId}&invoice=${_invoice
                      .text}&returnedItems=${_returnedItems.text}&amount=$amount')
                  .then((value) {
                Navigator.pop(context, "Reload");
              });
            }
        }
      else
          {
            showToastMessage('Please Select One Method of Pay!');
          }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 28),
                child: Image.asset(
                  'assets/Images/truckTravel.JPG',
                  // Set the height as per your requirement
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 40, right: 24, top: 20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(widget.cust.businessName,
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          width:  MediaQuery.of(context).size.width * 0.8,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child:  Text("Street: ${widget.cust.address1}",
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                width:  MediaQuery.of(context).size.width * 0.8,
                              ),
                              Divider(),
                              Text("City: ${widget.cust.city}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text("State: ${widget.cust.state}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text("ZIP Code: ${widget.cust.zipCode}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 45),
                child: Theme(
                  data: Theme.of(context).copyWith(

                    // dividerColor: Colors.transparent,
                    // dividerTheme: DividerThemeData(
                    //   color: Colors.transparent,
                    //   space: 0,
                    //   thickness: 0,
                    // ),
                  ),
                  child: ExpansionPanelList(
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
                            title: Text('Invoice',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        },
                        body: Column(
                          children: [
                            Padding(padding: const EdgeInsets.only(left:8.0,right:8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0XFFFAF8F8),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child:  Padding(padding: const EdgeInsets.only(left:16,right: 16,top:8,bottom: 8),
                                child:  TextField(
                                  controller: _invoice,
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),)
                          ],

                        ),
                      ),
                      ExpansionPanel(
                        isExpanded: _isExpandedList[1],
                        headerBuilder: (context, isExpanded) {
                          return ListTile(
                            title: Text('Amount Received',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
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
                                          TextSpan(text: 'Cash',
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
                                        controller: _cash,
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
                                          TextSpan(text: 'Cheque',
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
                                        controller: _cheque,
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
                                          TextSpan(text: 'Account',
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
                                        controller: _account,
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
                        isExpanded: _isExpandedList[2],
                        headerBuilder: (context, isExpanded) {
                          return ListTile(
                            title: Text('Returned Items',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        },
                        body: Column(
                          children: [
                            Padding(
                                padding: const EdgeInsets.only(left: 8.0,right: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0XFFFAF8F8),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child:  Padding(padding: const EdgeInsets.all(8.0),
                                  child:  TextField(
                                    controller: _returnedItems,
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                        'Submit', style: TextStyle(color: Color(0XFF6b619d))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
