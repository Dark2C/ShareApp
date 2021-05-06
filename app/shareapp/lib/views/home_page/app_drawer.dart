import 'package:flutter/material.dart';
import 'package:shareapp/globals.dart';
import 'package:shareapp/set_profile_photo.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class AppDrawer extends StatelessWidget {
  Function doLogoutAction, addContactAction, rubricaSyncAction;
  AppDrawer(
      {Function doLogoutAction,
      Function addContactAction,
      Function rubricaSyncAction}) {
    this.doLogoutAction = doLogoutAction;
    this.addContactAction = addContactAction;
    this.rubricaSyncAction = rubricaSyncAction;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          new Padding(padding: const EdgeInsets.all(36)),
          new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Padding(padding: const EdgeInsets.all(6)),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SetProfilePhoto()));
                    },
                    child: ClipOval(
                      child: new Image.network(
                          'https://' +
                              API_SERVER_ADDR +
                              '/avatars/' +
                              sharedPrefs.getString('avatar'),
                          fit: BoxFit.fill,
                          width: 64,
                          height: 64),
                    )),
                new Padding(padding: const EdgeInsets.all(12)),
                new Text(sharedPrefs.getString('username'),
                    style: new TextStyle(
                        fontSize: 21,
                        color: const Color(0xFFffffff),
                        fontWeight: FontWeight.w200,
                        fontFamily: "Roboto")),
                new Expanded(
                    child: new Padding(padding: const EdgeInsets.all(0))),
                new TextButton(
                    key: null,
                    onPressed: doLogoutAction,
                    child: new Icon(Icons.exit_to_app,
                        color: const Color(0xFFffffff), size: 24.0),
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                            vertical: 12, horizontal: 0)))),
                new Padding(padding: const EdgeInsets.all(6))
              ]),
          new Padding(padding: const EdgeInsets.all(8)),
          new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: TextButton(
                  onPressed: addContactAction,
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Padding(padding: const EdgeInsets.all(6)),
                        Text(
                          "Aggiungi contatto",
                          style:
                              new TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.left,
                        ),
                        Expanded(
                            child: Padding(padding: const EdgeInsets.all(0)))
                      ]),
                ))
              ]),
          new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: TextButton(
                  onPressed: rubricaSyncAction,
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Padding(padding: const EdgeInsets.all(6)),
                        Text(
                          "Sincronizza rubrica",
                          style:
                              new TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.left,
                        ),
                        Expanded(
                            child: Padding(padding: const EdgeInsets.all(0)))
                      ]),
                ))
              ]),
          new Expanded(child: new Padding(padding: const EdgeInsets.all(0))),
          new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: TextButton(
                  onPressed: () {
                    launch('https://github.com/Dark2C/ShareApp');
                  },
                  child: Opacity(
                      opacity: 0.6,
                      child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Padding(padding: const EdgeInsets.all(6)),
                            Text(
                              "Informazioni su ShareApp...",
                              style: new TextStyle(
                                  fontSize: 18, color: Colors.white),
                              textAlign: TextAlign.left,
                            ),
                            Expanded(
                                child:
                                    Padding(padding: const EdgeInsets.all(0)))
                          ])),
                ))
              ]),
        ]));
  }
}
