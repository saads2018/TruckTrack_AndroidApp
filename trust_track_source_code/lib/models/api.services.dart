import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_track/models/ImageInput.dart';

class APIservices {
  static String baseURL = '';
  static String origBaseURL = 'https://trucktrack.ddns.net:6002/';
  //static String origBaseURL = 'http://192.168.18.199:8099/';
  static String savedUsername = '';
  static String savedPassword = '';


  static Future<http.Response> fetchData(String ext) async {
    final response = await http.get(
        Uri.parse(baseURL + ext),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        }
    );
    return response;
  }

  static Future<http.Response> postData(String ext) async {

    final url = Uri.parse(baseURL + ext);
    final response = await http.post(url, headers: {
      "Content-Type": "application/json",
      "Accept": "application/json"
    });
    return response;
  }

  static Future<http.Response?> postDataToApi(String ext, ImageInput imageInput) async {
    try {
      // Replace 'your-api-endpoint' with the actual API endpoint URL.
      final apiUrl = Uri.parse(baseURL + ext);
      // Convert the custom object to JSON format.
      String jsonData = json.encode(imageInput.toJson());
      // Set the headers and body for the API request.
      Map<String, String> headers = {'Content-Type': 'application/json'};
      http.Response response = await http.post(apiUrl, headers: headers, body: jsonData);

      if (response.statusCode == 200) {
        print('POST request successful!');
        print('Response: ${response.body}');
      } else {
        print('Failed to make POST request. Status code: ${response.statusCode}');
        print('Error: ${response.body}');
      }
      return response;
    } catch (e) {
      print('Error making API request: $e');
      return null;
    }
  }


  static Future<void> saveBaseURL(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseURL', value);
    baseURL = value;
  }

  static Future<void> loadBaseURL() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('baseURL');
    if (value != null) {
      baseURL = value;
    }
  }

  static Future<void> saveUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedUsername', value);
    savedUsername = value;
  }

  static Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('savedUsername');
    if (value != null) {
      savedUsername = value;
    }
  }

  static Future<void> savePassword(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedPassword', value);
    savedPassword = value;
  }


  static Future<void> loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('savedPassword');
    if (value != null) {
      savedPassword = value;
    }
  }

  static Future<bool> checkConnectionToIP() async {
    try {
      var response = await APIservices.fetchData('Master/GetUsers').timeout(
          Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    }catch (e){
      return false;
    }
  }

  void main() async {
    await APIservices.loadBaseURL();
    await APIservices.loadUserName();
    await APIservices.loadPassword();
  }
}
