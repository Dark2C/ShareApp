import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String API_SERVER_ADDR = "ciampagliasandbox.altervista.org";
const String AVATAR_GENERATOR_SERVICE =
    "https://robohash.org/[RANDOM]?set=set4&bgset=bg1&size=256x256";
const String FIREBASE_SERVER_KEY =
    "AAAA-4XS_kU:APA91bHf3404WtBsanlb3ysuzhFVEvYWYpbT6g_o3C6IVOu-XBB-EfwoBGNYwBa414TtnjKZwNLjCvTJV_1rkUG1o_lmvxOiis4zo1EyixgMK8GKfL0W1lvgnPI8tBPcrwnSW-XGYtE5";
SharedPreferences sharedPrefs;

ThemeData appTheme = new ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF212121),
    accentColor: const Color(0xFF64ffda),
    canvasColor: const Color(0xFF303030));
String appName = 'ShareApp';
