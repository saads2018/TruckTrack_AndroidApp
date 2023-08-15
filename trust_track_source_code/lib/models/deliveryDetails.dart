class DeliveryDetails {
  int ID;
  int DeliveryID;
  String TruckNumber;
  int StartingMileage;
  String FuelTank_Starting;

  DeliveryDetails({
    required this.ID,
    required this.DeliveryID,
    required this.TruckNumber,
    required this.StartingMileage,
    required this.FuelTank_Starting,
  });

  factory DeliveryDetails.fromObject(Map<String, dynamic> map) {
    return DeliveryDetails(
        ID: map['ID'], // Update key to lowercase "deliveryId"
        DeliveryID: map['DeliveryID'],
        TruckNumber: map['TruckNumber'] ?? '',
        StartingMileage: map['StartingMileage'],
        FuelTank_Starting: map['FuelTank_Starting'], // Update key to lowercase "driverUserName"
    );
  }
}
