import 'dart:convert';
import 'dart:io';
import 'globals.dart';
import 'package:chunked_stream/chunked_stream.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
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
    sharedPrefs.remove('authKey').then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FirstScreen()),
      );
    });
  }

  void addContact() {
    final _usernameToAdd = TextEditingController();
    AlertDialog dialog = AlertDialog(
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
              if (_usernameToAdd.text.isNotEmpty) {
                http
                    .post(Uri.https(API_SERVER_ADDR, '/'),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(<String, dynamic>{
                          'request': 'addContact',
                          'authentication': sharedPrefs.getString('authKey'),
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
                    } else if (json['message'] == 'USERS_ALREADY_CONNECTED') {
                      errMsg = "Sei già connesso all'utente indicato!";
                    }
                    AlertDialog err = AlertDialog(title: Text(errMsg));
                    showDialog<void>(
                        context: context, builder: (context) => err);
                  }
                });
              }
            },
            child: Text("Aggiungi"))
      ],
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
        AlertDialog err = AlertDialog(
            title: Text(
                'Per sincronizzare la rubrica telefonica è necessario autorizzare l\'accesso ai contatti!'));
        showDialog<void>(context: context, builder: (context) => err);
      }
    } else {
      AlertDialog err = AlertDialog(
          title: Text(
              'Per sincronizzare la rubrica telefonica è necessario scegliere un numero di telefono!'));
      showDialog<void>(context: context, builder: (context) => err);
    }
  }

  void deleteContact(int id) {
    AlertDialog dialog = AlertDialog(
      title: Text("Elimina contatto"),
      content: Text(
        "Vuoi davvero eliminare il contatto selezionato dalla rubrica?",
        style: new TextStyle(fontSize: 18, color: Colors.white),
        textAlign: TextAlign.left,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text("Annulla")),
        new Expanded(child: new Padding(padding: const EdgeInsets.all(0))),
        TextButton(
            onPressed: () {
              http
                  .post(Uri.https(API_SERVER_ADDR, '/'),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: jsonEncode(<String, dynamic>{
                        'request': 'removeContact',
                        'authentication': sharedPrefs.getString('authKey'),
                        'user_ID': id
                      }))
                  .then((response) async {
                Navigator.of(context, rootNavigator: true).pop();
                Map<String, dynamic> json = jsonDecode(response.body);
                if (json['status'] == 'success') {
                  getRubrica();
                } else {
                  AlertDialog err = AlertDialog(
                      title: Text(
                          "È avvenuto un errore durante l'elaborazione della richiesta!"));
                  showDialog<void>(context: context, builder: (context) => err);
                }
              });
            },
            child: Text("Elimina"))
      ],
    );
    showDialog<void>(context: context, builder: (context) => dialog);
  }

  String fileSizeBeautify(int bytesN) {
    String prefix = "";
    double bl = bytesN.toDouble();
    if (bl > 768) {
      bl /= 1024;
      prefix = "K";
    }
    if (bl > 768) {
      bl /= 1024;
      prefix = "M";
    }
    if (bl > 768) {
      bl /= 1024;
      prefix = "G";
    }
    if (bl > 768) {
      bl /= 1024;
      prefix = "T";
    }
    return bl.toStringAsFixed(2) + " " + prefix + "B";
  }

  void sendFileTo(int id, String receiverUsername) async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      bool canceledBySender = false, aborted = false;
      StateSetter _setDialogTitle, _setDialogContent, _setPercentualState;
      Socket socket;

      //TODO (firebase request)

      Widget dialogTitle =
          Text("Ottenimento informazioni sul file in corso...");
      // appezzottamento suggerito dallo stesso flutter... Che dire, chapeau!
      Widget dialogContent = Container(width: 0, height: 0);
      List<Widget> dialogActions = [
        TextButton(
            onPressed: () {
              canceledBySender = true;
              Navigator.of(context, rootNavigator: true).pop();
              try {
                socket.close();
                socket.destroy();
              } catch (e) {}
            },
            child: Text("Annulla"))
      ];
      Widget _dialogBody = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: dialogActions)
          ]);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                _setDialogTitle = setState;
                return dialogTitle;
              },
            ),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                _setDialogContent = setState;
                return _dialogBody;
              },
            ),
          );
        },
      );

      PlatformFile fileInfo = result.files.single;
      File file = File(result.files.single.path);

      await Future.delayed(Duration(milliseconds: 25));

      dialogTitle = Text("Connessione a " + receiverUsername + " in corso...");
      _setDialogTitle(() {});

      http.Response resp = await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'senderStart',
            'authentication': sharedPrefs.getString('authKey'),
            'receiver': id,
            'fileName': fileInfo.name,
            'fileSize': fileInfo.size
          }));
      if (!canceledBySender) {
        Map<String, dynamic> json = jsonDecode(resp.body);
        if (json["status"] == "success") {
          // comincia lo scambio del file vero e proprio

          dialogTitle = Text("Connessione al server di tunnel in corso...");
          _setDialogTitle(() {});

          // mi connetto al tunnel indicato nella risposta
          try {
            socket = await Socket.connect(
                json["tunnelHost"], json["tunnelPort"],
                timeout: Duration(seconds: 5));

            if (!canceledBySender) {
              double percentuale = 0;
              dialogTitle = Text("Invio in corso...");
              _dialogBody = Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Puoi minimizzare l'app durante l'invio del file."),
                  Divider(color: const Color(0x5e5e5e)),
                  Text("Nome file: " + fileInfo.name),
                  Text("Dimensioni: " + fileSizeBeautify(fileInfo.size)),
                  Text("Destinatario: " + receiverUsername),
                  new Padding(padding: const EdgeInsets.all(6)),
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      _setPercentualState = setState;
                      return LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 128,
                        animation: false,
                        lineHeight: 20.0,
                        percent: percentuale,
                        center:
                            Text((percentuale * 100).toStringAsFixed(2) + "%"),
                        linearStrokeCap: LinearStrokeCap.roundAll,
                        progressColor: Colors.greenAccent,
                      );
                    },
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () {
                          canceledBySender = true;
                          Navigator.of(context, rootNavigator: true).pop();
                          try {
                            socket.close();
                            socket.destroy();
                          } catch (e) {}
                        },
                        child: Text("Annulla"))
                  ])
                ],
              );

              _setDialogTitle(() {});
              _setDialogContent(() {});

              socket.drain().then((value) {
                aborted = true;
              });

              // mi identifico come sender
              socket.add(utf8.encode(json["sessKey"] + "S"));
              // invio i dati verso il tunnel

              // stabilisco, arbitrariamente, che un chunk è 1 MB
              final chunkSize = 1024 * 1024;
              final reader = ChunkedStreamIterator(file.openRead());
              List<int> chunk;
              int chunkCount =
                      (fileInfo.size.toDouble() / chunkSize).ceil().toInt(),
                  chunkIndex = 0;
              try {
                while (!canceledBySender && !aborted) {
                  chunk = await reader.read(chunkSize);
                  socket.add(chunk);
                  chunkIndex++;
                  percentuale = chunkIndex.toDouble() / chunkCount.toDouble();
                  _setPercentualState(() {});
                  if (chunk.length < chunkSize) break;
                }
              } catch (e) {
                aborted = true;
              }
              try {
                socket.flush().then((value) {
                  socket.close();
                });
                await socket.done;
                if (!canceledBySender) {
                  if (!aborted) {
                    dialogTitle = Text("Trasferimento completato!");
                  } else {
                    dialogTitle = Text("Il trasferimento è stato interrotto!");
                  }
                }
              } catch (e) {
                aborted = true;
                dialogTitle =
                    Text("C'è stato un errore durante il trasferimento!");
              }
              if (!canceledBySender || aborted) {
                _dialogBody =
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () {
                        canceledBySender = true;
                        Navigator.of(context, rootNavigator: true).pop();
                        try {
                          socket.close();
                          socket.destroy();
                        } catch (e) {}
                      },
                      child: Text("Chiudi"))
                ]);
                _setDialogTitle(() {});
                _setDialogContent(() {});
              }
            }
          } catch (e) {
            dialogTitle = Text(
                "C'è stato un errore durante la connessione al server di tunnel!");
            _setDialogTitle(() {});
            try {
              socket.close();
            } catch (e) {}
          }

          // chiudo la connessione

        } else if (json["status"] == "error") {
          dialogActions = [
            TextButton(
                onPressed: () {
                  canceledBySender = true;
                  Navigator.of(context, rootNavigator: true).pop();
                  try {
                    socket.close();
                    socket.destroy();
                  } catch (e) {}
                },
                child: Text("Chiudi"))
          ];
          if (json["message"] == "REFUSED_BY_RECEIVER")
            dialogTitle = Text("L'utente ha rifiutato la ricezione del file!");
          else if (json["message"] == "TIMEOUT_REACHED")
            dialogTitle = Text(
                "L'utente non ha risposto alla richiesta di ricezione del file!");
          else if (json["message"] == "USERS_NOT_CONNECTED") {
            dialogTitle = Text("Tu e " +
                receiverUsername +
                " non siete reciprocamente collegati!");
            dialogContent = Text(
                "Prima di poter procedere con l'invio, assicurati che " +
                    receiverUsername +
                    " ti abbia aggiunto tra i suoi contatti.");
          } else
            dialogTitle =
                Text("Errore durante il completamento della richiesta!");
        } else
          dialogTitle =
              Text("Errore durante il completamento della richiesta!");
        _dialogBody = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              dialogContent,
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: dialogActions)
            ]);
        _setDialogTitle(() {});
        _setDialogContent(() {});
      }
    }
  }

  void getRubrica() async {
    contactsList.clear();
    http.Response resp = await http.post(Uri.https(API_SERVER_ADDR, '/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'request': 'listContacts',
          'authentication': sharedPrefs.getString('authKey')
        }));

    Map<String, dynamic> json = jsonDecode(resp.body);
    if (json['status'] == 'success') {
      DateFormat dateFormat = DateFormat("dd/MM/yyyy HH:mm");

      for (var contactItem in json['contacts']) {
        contactsList.add(new TextButton(
            key: null,
            onPressed: () {
              sendFileTo(contactItem['ID'], contactItem['username']);
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
