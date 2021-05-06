import 'globals.dart';
import 'package:flutter/material.dart';
import 'views/set_profile_photo/set_profile_photo.dart';

class SetProfilePhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: appName,
        theme: appTheme,
        home: MySetProfilePhoto(title: appName));
  }
}