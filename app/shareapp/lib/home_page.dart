import 'globals.dart';
import 'package:flutter/material.dart';
import 'views/home_page/home_page.dart';
import 'package:firebase_core/firebase_core.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Text(
              "C'è stato un errore nella connessione a firebase! Riavvia l'app e riprova.");
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
              title: appName,
              theme: appTheme,
              home: MyHomePage(title: appName));
        }
        return CircularProgressIndicator();
      },
    );
  }
}