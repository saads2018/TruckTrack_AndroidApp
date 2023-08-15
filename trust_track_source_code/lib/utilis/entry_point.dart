import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trust_track/screens/home/home_screen.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({Key? key, required this.data, this.controller, required this.initializeControllerFuture}) : super(key: key);
  final String data;
  final CameraController? controller;
  final Future<void> initializeControllerFuture;
  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          HomeScreen(
              data: widget.data,
            controller: widget.controller,
            initializeControllerFuture: widget.initializeControllerFuture,
          ),
          //MenuBtn(press: () {  },),
        ],
      ),
    );
  }
}

class MenuBtn extends StatelessWidget {
  const MenuBtn({
    super.key, required this.press, //required this.iconOnInit,
  });

  final VoidCallback press;
  //final ValueChanged<AnimatedIconData> iconOnInit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: press,
        child: Container(
          margin: EdgeInsets.only(left:16),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow:  [
              BoxShadow(
              color: Colors.black,
              offset:Offset(0,3),
              blurRadius: 8,
            ),
            ],
          ),
          child: Icon(Icons.menu),
        ),
      ),
    );
  }
}
