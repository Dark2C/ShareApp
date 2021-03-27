import 'dart:convert';
import 'dart:io';
import 'globals.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shareapp/main.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:url_launcher/url_launcher.dart';

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
            canvasColor: const Color(0xFF303030)),
        home: MyHomePage(title: 'ShareApp'));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String myPhoneNumber;
  bool isFirstStart = true;

  List<Widget> contactsList = [];

  @override
  Widget build(BuildContext context) {
    try {
      myPhoneNumber = sharedPrefs.getString('phoneNumber');
    } catch (e) {
      myPhoneNumber = null;
    }

    if (isFirstStart) {
      rubricaSync(askForNumber: false);
      getRubrica();
      isFirstStart = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: contactsList),
      ),
      drawer: Drawer(
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
                  new ClipOval(
                    child: new Image.network(
                        'https://' +
                            API_SERVER_ADDR +
                            '/avatars/' +
                            sharedPrefs.getString('avatar'),
                        fit: BoxFit.fill,
                        width: 64,
                        height: 64),
                  ),
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
                      onPressed: doLogout,
                      child: new Icon(Icons.exit_to_app,
                          color: const Color(0xFFffffff), size: 24.0),
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
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
                    onPressed: addContact,
                    child: new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Padding(padding: const EdgeInsets.all(6)),
                          Text(
                            "Aggiungi contatto",
                            style: new TextStyle(
                                fontSize: 18, color: Colors.white),
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
                    onPressed: rubricaSync,
                    child: new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Padding(padding: const EdgeInsets.all(6)),
                          Text(
                            "Sincronizza rubrica",
                            style: new TextStyle(
                                fontSize: 18, color: Colors.white),
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
          ])),
    );
  }

  void doLogout() {
    isFirstStart = true;
    setState(() {});
    /*
    sharedPrefs.remove('authKey').then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FirstScreen()),
      );
    });*/
  }

  void addContact() {
    final _usernameToAdd = TextEditingController();
    var dialog = AlertDialog(
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
            ),
            Padding(
              padding: const EdgeInsets.all(6),
            ),
            TextButton(
                onPressed: () {
                  if (_usernameToAdd.text.isNotEmpty) {
                    http
                        .post(Uri.https(API_SERVER_ADDR, '/'),
                            headers: <String, String>{
                              'Content-Type': 'application/json; charset=UTF-8',
                            },
                            body: jsonEncode(<String, dynamic>{
                              'request': 'addContact',
                              'authentication':
                                  sharedPrefs.getString('authKey'),
                              'username': _usernameToAdd.text
                            }))
                        .then((response) async {
                      Navigator.of(context, rootNavigator: true).pop();
                      Map<String, dynamic> json = jsonDecode(response.body);
                      if (json['status'] == 'success') {
                        getRubrica();
                      } else {
                        String errMsg =
                            "È avvenuto un errore durante l'elaborazione della richiesta!";
                        if (json['message'] == 'USER_NOT_FOUND') {
                          errMsg = "L'utente indicato non è stato trovato!";
                        } else if (json['message'] ==
                            'USERS_ALREADY_CONNECTED') {
                          errMsg = "Sei già connesso all'utente indicato!";
                        }
                        var err = AlertDialog(title: Text(errMsg));
                        showDialog<void>(
                            context: context, builder: (context) => err);
                      }
                    });
                  }
                },
                child: Text("Aggiungi", style: new TextStyle(fontSize: 24.0)),
                style: ButtonStyle(
                    side: MaterialStateProperty.all(
                        BorderSide(width: 2, color: Colors.blueGrey)),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 36))))
          ]),
    );
    showDialog<void>(context: context, builder: (context) => dialog);
  }

  void rubricaSync({bool askForNumber = true}) async {
    if (askForNumber || myPhoneNumber == null) {
      final SmsAutoFill _autoFill = SmsAutoFill();
      myPhoneNumber = await _autoFill.hint;
    }
    if (myPhoneNumber != null) {
      await sharedPrefs.setString('phoneNumber', myPhoneNumber);

      if (await Permission.contacts.request().isGranted) {
        Iterable<Contact> contacts =
            await ContactsService.getContacts(withThumbnails: false);

        List<String> numbers = [];
        for (var contact in contacts) {
          for (var phone in contact.phones) {
            numbers.add(phone.value.replaceAll(' ', ''));
          }
        }
        numbers = numbers.toSet().toList(); // rimuovi eventuali duplicati
        await http.post(Uri.https(API_SERVER_ADDR, '/'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, dynamic>{
              'request': 'syncAddressBook',
              'authentication': sharedPrefs.getString('authKey'),
              'myPhoneNumber': myPhoneNumber,
              'contacts': numbers
            }));
        if (!isFirstStart) setState(() {}); // refresh
        return;
      } else {
        var err = AlertDialog(
            title: Text(
                'Per sincronizzare la rubrica telefonica è necessario autorizzare l\'accesso ai contatti!'));
        showDialog<void>(context: context, builder: (context) => err);
      }
    } else {
      var err = AlertDialog(
          title: Text(
              'Per sincronizzare la rubrica telefonica è necessario scegliere un numero di telefono!'));
      showDialog<void>(context: context, builder: (context) => err);
    }
  }

  void deleteContact(int id) {
    var dialog = AlertDialog(
      title: Text("Elimina contatto"),
      content: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Vuoi davvero eliminare il contatto selezionato dalla rubrica?",
              style: new TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.left,
            ),
            Padding(
              padding: const EdgeInsets.all(6),
            ),
            new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child:
                          Text("Annulla", style: new TextStyle(fontSize: 21.0)),
                      style: ButtonStyle(
                          side: MaterialStateProperty.all(
                              BorderSide(width: 2, color: Colors.blueGrey)),
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 24)))),
                  TextButton(
                      onPressed: () {
                        http
                            .post(Uri.https(API_SERVER_ADDR, '/'),
                                headers: <String, String>{
                                  'Content-Type':
                                      'application/json; charset=UTF-8',
                                },
                                body: jsonEncode(<String, dynamic>{
                                  'request': 'removeContact',
                                  'authentication':
                                      sharedPrefs.getString('authKey'),
                                  'user_ID': id
                                }))
                            .then((response) async {
                          Navigator.of(context, rootNavigator: true).pop();
                          Map<String, dynamic> json = jsonDecode(response.body);
                          if (json['status'] == 'success') {
                            getRubrica();
                          } else {
                            var err = AlertDialog(
                                title: Text(
                                    "È avvenuto un errore durante l'elaborazione della richiesta!"));
                            showDialog<void>(
                                context: context, builder: (context) => err);
                          }
                        });
                      },
                      child: Text("Elimina",
                          style: new TextStyle(
                              fontSize: 21.0, color: Colors.white)),
                      style: ButtonStyle(
                          side: MaterialStateProperty.all(
                              BorderSide(width: 2, color: Colors.red)),
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 24)),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.red)))
                ])
          ]),
    );
    showDialog<void>(context: context, builder: (context) => dialog);
  }

  void sendFileTo(int id) async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile fileInfo = result.files.single;
      print(fileInfo.name);
      print(fileInfo.size);
      //File file = File(result.files.single.path);
      //TODO
    }
  }

  void getRubrica() async {
    contactsList.clear();
    http.Response response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'request': 'listContacts',
          'authentication': sharedPrefs.getString('authKey')
        }));

    Map<String, dynamic> json = jsonDecode(response.body);
    if (json['status'] == 'success') {
      DateFormat dateFormat = DateFormat("dd/MM/yyyy HH:mm");

      for (var contactItem in json['contacts']) {
        contactsList.add(new TextButton(
            key: null,
            onPressed: () {
              sendFileTo(contactItem['ID']);
            },
            onLongPress: () {
              deleteContact(contactItem['ID']);
            },
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Padding(padding: const EdgeInsets.all(6)),
                  new ClipOval(
                    child: new Image.network(
                      'https://' +
                          API_SERVER_ADDR +
                          '/avatars/' +
                          contactItem['avatar'],
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
                          contactItem['username'],
                          style: new TextStyle(
                              fontSize: 24.0,
                              color: const Color(0xFFffffff),
                              fontWeight: FontWeight.w700,
                              fontFamily: "Roboto"),
                        ),
                        new Padding(padding: const EdgeInsets.all(1.5)),
                        new Text(
                          "Ultimo accesso: " +
                              dateFormat.format(
                                  DateTime.parse(contactItem['lastSeen'])),
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
                    EdgeInsets.symmetric(vertical: 12, horizontal: 0)))));
      }
      setState(() {});
    }
  }
}
