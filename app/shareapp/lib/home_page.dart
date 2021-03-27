import 'package:shareapp/main.dart';

import 'globals.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareApp',
      theme: new ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF212121),
        accentColor: const Color(0xFF64ffda),
        canvasColor: const Color(0xFF303030),
      ),
      home: MyHomePage(title: 'ShareApp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('TODO',
            style: new TextStyle(
                fontSize: 48.0,
                color: const Color(0xFFffffff),
                fontWeight: FontWeight.w900,
                fontFamily: "Roboto")),
      ),
      drawer: Drawer(
          child: new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
            new Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 72.0, 0, 0.0),
            ),
            new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 12.0, 0.0),
                  ),
                  new ClipOval(
                    child: new Image.network(
                      'https://' +
                          API_SERVER_ADDR +
                          '/avatars/' +
                          sharedPrefs.getString('avatar'),
                      fit: BoxFit.fill,
                      width: 64.0,
                      height: 64.0,
                    ),
                  ),
                  new Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 24.0, 0.0),
                  ),
                  new Text(
                    sharedPrefs.getString('username'),
                    style: new TextStyle(
                        fontSize: 21.0,
                        color: const Color(0xFFffffff),
                        fontWeight: FontWeight.w200,
                        fontFamily: "Roboto"),
                  ),
                  new Expanded(
                      child: new Padding(
                    padding: const EdgeInsets.all(0),
                  )),
                  new TextButton(
                      key: null,
                      onPressed: doLogout,
                      child: new Icon(Icons.exit_to_app,
                          color: const Color(0xFFffffff), size: 24.0),
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 0)))),
                  new Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 12.0, 0.0),
                  ),
                ])
          ])),
    );
  }

  void doLogout() {
    sharedPrefs.remove('authKey').then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FirstScreen()),
      );
    });
  }
}
