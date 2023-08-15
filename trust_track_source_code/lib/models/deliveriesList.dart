import 'dart:ui';

class DeliveriesList {
  int deliveryId;
  String deliveryDriver;
  String deliveryRoutes;
  String deliveryTimes;
  String deliveryStatus;
  String driverUserName; // Update property name to "driverUserName"
  String routeAddresses;

  DeliveriesList({
    required this.deliveryId,
    required this.deliveryDriver,
    required this.deliveryRoutes,
    required this.deliveryTimes,
    required this.deliveryStatus,
    required this.driverUserName,
    required this.routeAddresses,
  });

  factory DeliveriesList.fromObject(Map<String, dynamic> map) {
    return DeliveriesList(
      deliveryId: map['deliveryId'], // Update key to lowercase "deliveryId"
      deliveryDriver: map['deliveryDriver'],
      deliveryRoutes: map['deliveryRoutes'],
      deliveryTimes: map['deliveryTimes'] ?? '',
      deliveryStatus: map['deliveryStatus'],
      driverUserName: map['driverUserName'], // Update key to lowercase "driverUserName"
      routeAddresses: map['routeAddresses'],
    );
  }
}

class Point{
  double? x;
  double? y;

  Point(this.x, this.y);
}
