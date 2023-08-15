class CustomersList {
  int custId;
  String firstName;
  String lastName;
  String businessName;
  String address1;
  String address2;
  String city;
  String state;
  String zipCode;
  String route;
  int? stop;

  CustomersList({
    required this.custId,
    required this.firstName,
    required this.lastName,
    required this.businessName,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.route,
    required this.stop,
  });

  factory CustomersList.fromObject(Map<String, dynamic> map) {
    return CustomersList(
      custId: map['custId'],
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      businessName: map['businessName'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      route: map['route'] ?? '',
      stop: map['stop'],
    );
  }
}
