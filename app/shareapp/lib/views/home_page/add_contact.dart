import 'package:flutter/material.dart';

class AddContact extends AlertDialog {
  Function addContactAction, getRubricaAction;
  AddContact({Function addContactAction,Function getRubricaAction }) {
    this.addContactAction = addContactAction;
  }

  @override
  Widget build(BuildContext context) {
    final _usernameToAdd = TextEditingController();
    return AlertDialog(
      title: Text("Aggiungi contatto:"),
      content: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Nota: per inviare file al contatto, è necessario che anche lui ti aggiunga nella sua rubrica.",
              style: new TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.left,
            ),
            TextFormField(
              controller: _usernameToAdd,
              decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  hintText: 'Username',
                  contentPadding: EdgeInsets.all(20.0)),
            )
          ]),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              addContactAction(_usernameToAdd.text).then((res) {
                if (res == 0)
                  getRubricaAction();
                else {
                  String errMsg =
                      "È avvenuto un errore durante l'elaborazione della richiesta!";
                  if (res == -1)
                    errMsg = "L'utente indicato non è stato trovato!";
                  else if (res == -2)
                    errMsg = "Sei già connesso all'utente indicato!";
                  AlertDialog err = AlertDialog(title: Text(errMsg));
                  showDialog<void>(context: context, builder: (context) => err);
                }
              });
            },
            child: Text("Aggiungi"))
      ],
    );
  }
}
