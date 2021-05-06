import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class UserItem extends StatelessWidget {
  Function onPressed, onLongPress;
  String userName, userImagePath, lastSeen;
  UserItem(
      {Function onPressed,
      Function onLongPress,
      String userName,
      String userImagePath,
      String lastSeen}) {
    this.onPressed = onPressed;
    this.onLongPress = onLongPress;
    this.userName = userName;
    this.userImagePath = userImagePath;
    this.lastSeen = lastSeen;
  }

  @override
  Widget build(BuildContext context) {
    DateFormat dateFormat = DateFormat("dd/MM/yyyy HH:mm");
    return new TextButton(
        key: null,
        onPressed: this.onPressed,
        onLongPress: this.onLongPress,
        child: new Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Padding(padding: const EdgeInsets.all(6)),
              new ClipOval(
                child: new Image.network(
                  this.userImagePath,
                  fit: BoxFit.fill,
                  width: 64.0,
                  height: 64.0,
                ),
              ),
              new Padding(padding: const EdgeInsets.all(6)),
              new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(
                      userName,
                      style: new TextStyle(
                          fontSize: 24.0,
                          color: const Color(0xFFffffff),
                          fontWeight: FontWeight.w700,
                          fontFamily: "Roboto"),
                    ),
                    new Padding(padding: const EdgeInsets.all(1.5)),
                    new Text(
                      "Ultimo accesso: " +
                          dateFormat.format(DateTime.parse(lastSeen)),
                      style: new TextStyle(
                          fontSize: 16.0,
                          color: const Color(0xFFffffff),
                          fontWeight: FontWeight.w200,
                          fontFamily: "Roboto"),
                    )
                  ])
            ]),
        style: ButtonStyle(
            padding: MaterialStateProperty.all(
                EdgeInsets.symmetric(vertical: 12, horizontal: 0))));
  }
}
