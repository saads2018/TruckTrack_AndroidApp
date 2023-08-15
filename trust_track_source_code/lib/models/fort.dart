import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Fort{
  final String title;
  String description;
  String address;
  String formStatus;
  Color bgColor,textColor, iconClr, divColor, descColor,formStatusColor;
  final IconData iconSrc;

  Fort({
    required this.title,
    this.address = "Address",
    this.description = "[ Pending ]",
    this.iconSrc = Icons.fire_truck_rounded,
    this.bgColor = const Color(0XFFf7f5ff),
    this.textColor = const Color(0XFF4e4773),
    this.iconClr = Colors.white,
    this.divColor = Colors.white70,
    this.descColor = Colors.black,
    this.formStatus = "",
    this.formStatusColor = Colors.black,
  });
}

List<Fort> forts = [
  Fort(title: "Warehouse",
  iconSrc: Icons.location_on_sharp),
];

List<Fort> recentForts = [
  Fort(title: "State Machine"),
  Fort(title: "Animated Menu",
    iconSrc: Icons.earbuds,
    bgColor: Color(0XFFf7f5ff),
  ),
  Fort(title: "Flutter with Rive"),
  Fort(title: "Animated Menu",
    iconSrc: Icons.earbuds,
    bgColor: Color(0XFFf7f5ff),
  ),
];