import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'info_card.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
        width: 288,
        height: double.infinity,
        color: Color(0XFF17203A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              name:"Saud Sultan",
              profession: "Truck Driver",
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top:32, bottom:16),
              child: Text(
                "OPTIONS",
                style: TextStyle(
                    color: Colors.white70
                ),
              ),
            ),
            SideMenuTile(),
          ],
        ),
      ),
    );
  }
}

class SideMenuTile extends StatelessWidget {
  const SideMenuTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left:24.0),
          child: Divider(
            color: Colors.white24,
            height: 1,
          ),
        ),
        ListTile(
          onTap: (){},
          leading: SizedBox(
            height: 34,
            width: 34,
            child: Icon(
                Icons.exit_to_app,
                color:Colors.white),
          ),
          title: Text("Log Out",
            style: TextStyle(color: Colors.white),
          ),

        ),
      ],
    );
  }
}