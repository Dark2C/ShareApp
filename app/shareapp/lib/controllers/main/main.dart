import 'dart:convert';
import '../../globals.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainController {
  TextEditingController _username;
  TextEditingController _password;

  MainController(
      TextEditingController username, TextEditingController password) {
    _username = username;
    _password = password;
  }

  bool _isLogged = false;

  bool isLogged() {
    return _isLogged;
  }

  Future<bool> checkLogin() async {
    try {
      sharedPrefs = await SharedPreferences.getInstance();
      if (sharedPrefs.getString('authKey').isEmpty) return false;
    } catch (e) {
      return false;
    }

    http.Response resp = await http.post(Uri.https(API_SERVER_ADDR, '/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'request': 'getCurrentUser',
          'authentication': sharedPrefs.getString('authKey'),
        }));
    Map<String, dynamic> json = jsonDecode(resp.body);
    if (json['status'] == 'success') {
      await sharedPrefs.setInt('user_ID', json['user_ID']);
      await sharedPrefs.setString('username', json['username']);
      await sharedPrefs.setString('avatar', json['avatar']);
      return true;
    } else if (json['status'] == 'error') {
      try {
        await sharedPrefs.remove('authKey');
      } catch (e) {}
      try {
        await sharedPrefs.remove('user_ID');
      } catch (e) {}
      try {
        await sharedPrefs.remove('username');
      } catch (e) {}
      try {
        await sharedPrefs.remove('avatar');
      } catch (e) {}
    }
    return false;
  }

  Future<void> init() async {
    sharedPrefs = await SharedPreferences.getInstance();
    _isLogged = await checkLogin();
  }

  bool areFieldsFilled() {
    return (!(_username.text.isEmpty || _password.text.isEmpty));
  }

  Future<int> handleLogin() async {
    if (areFieldsFilled()) {
      var response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'login',
            'authentication': {
              'username': _username.text,
              'password': _password.text
            },
          }));

      Map<String, dynamic> json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        await sharedPrefs.setString('authKey', json['authKey']);
        if (await checkLogin())
          return 0;
        else
          return -1;
      } else
        return -2;
    } else
      return -1;
  }

  Future<int> handleRegistration() async {
    if (areFieldsFilled()) {
      var response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'register',
            'authentication': {
              'username': _username.text,
              'password': _password.text
            },
          }));
      Map<String, dynamic> json = jsonDecode(response.body);

      if (json['status'] == 'success') {
        await sharedPrefs.setString('authKey', json['authKey']);
        if (await checkLogin())
          return 0;
        else
          return -1;
      } else
        return -2;
    } else
      return -1;
  }
}
