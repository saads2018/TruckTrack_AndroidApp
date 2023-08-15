class ImageInput {
  String Base64Image;
  int id;
  String driverEmail;
  String driverName;

  ImageInput(this.Base64Image, this.id,this.driverEmail,this.driverName);

  Map<String, dynamic> toJson() {
    return {
      'base64Image': Base64Image,
      'id': id,
      'driverEmail':driverEmail,
      'driverName':driverName,
    };
  }
}