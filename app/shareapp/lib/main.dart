import 'globals.dart';
import 'package:flutter/material.dart';
import 'views/main/main.dart';

void main() {
  runApp(FirstScreen());
}

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: appName, theme: appTheme, home: MyLoginForm(title: appName));
  }
}
