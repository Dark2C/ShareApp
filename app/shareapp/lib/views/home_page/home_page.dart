import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:chunked_stream/chunked_stream.dart';
import 'package:crypto/crypto.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shareapp/controllers/home_page/home_page.dart';
import 'package:shareapp/globals.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/views/home_page/app_drawer.dart';
import 'add_contact.dart';
import 'user_item.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  HomePageController homePageController;
  bool isFirstStart = true;
  List<Widget> contactsList = [];

  @override
  void initState() {
    homePageController = new HomePageController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    homePageController.getMyPhoneNumber();
    if (isFirstStart) {
      rubricaSync(askForNumber: false);
      getRubrica();
      isFirstStart = false;
      homePageController.startFirebaseListener(handleFileReceive);
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
        drawer: AppDrawer(
            doLogoutAction: () {
              homePageController.doLogout().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => FirstScreen()),
                );
              });
            },
            addContactAction: addContact,
            rubricaSyncAction: rubricaSync));
  }

  void addContact() {
    AlertDialog dialog = AddContact(
        addContactAction: homePageController.addContact,
        getRubricaAction: getRubrica);
    showDialog<void>(context: context, builder: (context) => dialog);
  }

  void rubricaSync({bool askForNumber = true}) async {
    int res = await homePageController.rubricaSync(askForNumber: askForNumber);
    if (res == 0) {
      if (!isFirstStart) setState(() {}); // refresh
    } else if (res == -1) {
      AlertDialog err = AlertDialog(
          title: Text(
              'Per sincronizzare la rubrica telefonica ?? necessario autorizzare l\'accesso ai contatti!'));
      showDialog<void>(context: context, builder: (context) => err);
    } else if (res == -2) {
      AlertDialog err = AlertDialog(
          title: Text(
              'Per sincronizzare la rubrica telefonica ?? necessario scegliere un numero di telefono!'));
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
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              if (await homePageController.deleteContact(id) == 0)
                getRubrica();
              else {
                AlertDialog err = AlertDialog(
                    title: Text(
                        "?? avvenuto un errore durante l'elaborazione della richiesta!"));
                showDialog<void>(context: context, builder: (context) => err);
              }
            },
            child: Text("Elimina"))
      ],
    );
    showDialog<void>(context: context, builder: (context) => dialog);
  }

  void sendFileTo(
      int id, String receiverUsername, String receiverFirebaseToken) async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile fileInfo = result.files.single;
      File file = File(result.files.single.path);
      bool canceledBySender = false, aborted = false, completed = false;
      StateSetter _setDialogTitle, _setDialogContent, _setPercentualState;
      Socket socket;

      Widget dialogTitle =
          Text("Ottenimento informazioni sul file in corso...");
      // appezzottamento suggerito dallo stesso flutter... Che dire, chapeau!
      Widget dialogContent = Container(width: 0, height: 0);
      List<Widget> dialogActions = [
        TextButton(
            onPressed: () {
              canceledBySender = true;
              Navigator.of(context, rootNavigator: true).pop();
              if (!completed) {
                try {
                  socket.close();
                  socket.destroy();
                } catch (e) {}
              }
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

      await Future.delayed(Duration(milliseconds: 25));

      dialogTitle = Text("Connessione a " + receiverUsername + " in corso...");
      _setDialogTitle(() {});

      var apiReq = http.post(Uri.https(API_SERVER_ADDR, '/'),
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

      // invio messaggio via firebase:
      http.post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'key=' + FIREBASE_SERVER_KEY,
          },
          body: jsonEncode(<String, dynamic>{
            'notification': {
              'title': "Richiesta di invio file...",
              'body': sharedPrefs.getString('username') +
                  ' desidera inviarti un file...'
            },
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'fileName': fileInfo.name,
              'fileSize': fileInfo.size,
              'senderName': sharedPrefs.getString('username')
            },
            'to': receiverFirebaseToken
          }));

      http.Response resp = await apiReq;

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

            socket.setOption(SocketOption.tcpNoDelay, true);

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
                  Text("Dimensioni: " +
                      homePageController.fileSizeBeautify(fileInfo.size)),
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

              /*socket.drain().then((value) {
                aborted = true;
              });*/

              // mi identifico come sender
              socket.add(utf8.encode(json["sessKey"]));
              // invio i dati verso il tunnel

              // stabilisco, arbitrariamente, che un chunk ?? composto da 24 MTU
              final int chunkSize = 24 * 1492 - 37;
              final reader = ChunkedStreamIterator(file.openRead());
              List<int> chunk;
              int chunkCount =
                      (fileInfo.size.toDouble() / chunkSize).ceil().toInt(),
                  chunkIndex = 0;
              try {
                bool inPause = false, lastOk = false;

                String esito = "";
                StreamSubscription respByRecv = socket.listen((resp) {
                  esito = esito + utf8.decode(resp).toLowerCase();
                  // sostanzialmente se la stringa in risposta ha pi?? s che n, il chunk ?? corretto
                  lastOk = esito.replaceAll('n', '').length >
                      esito.replaceAll('s', '').length;
                  if (esito.length == 32) {
                    esito = "";
                    inPause = false;
                  }
                });

                bool watchdog = false;
                var watchdogStream =
                    Stream<void>.periodic(Duration(seconds: 5), (_) {})
                        .listen((event) {
                  if (watchdog) {
                    try {
                      socket.close();
                      aborted = true;
                    } catch (e) {}
                  } else
                    watchdog = true;
                });

                while (!canceledBySender && !aborted) {
                  chunk = await reader.read(chunkSize);
                  do {
                    watchdog = false;
                    socket.add(utf8.encode(chunk.length.toString() + '|'));
                    socket.add(utf8.encode(md5.convert(chunk).toString()));
                    socket.add(chunk);
                    inPause = true;
                    while (inPause && (!canceledBySender && !aborted)) {
                      await Future.delayed(Duration(milliseconds: 1));
                    }
                  } while (!lastOk && (!canceledBySender && !aborted));
                  chunkIndex++;
                  percentuale = chunkIndex.toDouble() / chunkCount.toDouble();
                  _setPercentualState(() {});
                  if (chunk.length < chunkSize) break;
                }
                watchdogStream.cancel();
                respByRecv.cancel();
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
                    dialogTitle = Text("Il trasferimento ?? stato interrotto!");
                  }
                }
              } catch (e) {
                aborted = true;
                dialogTitle =
                    Text("C'?? stato un errore durante il trasferimento!");
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
                "C'?? stato un errore durante la connessione al server di tunnel!");
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
      for (var contactItem in json['contacts']) {
        contactsList.add(new UserItem(
            onPressed: () {
              sendFileTo(contactItem['ID'], contactItem['username'],
                  contactItem['firebaseToken']);
            },
            onLongPress: () {
              deleteContact(contactItem['ID']);
            },
            userName: contactItem['username'],
            userImagePath: 'https://' +
                API_SERVER_ADDR +
                '/avatars/' +
                contactItem['avatar'],
            lastSeen: contactItem['lastSeen']));
      }
      setState(() {});
    }
  }

  void handleFileReceive(
      String fileName, dynamic fileSize, String senderName) async {
    int fileSizeInt = int.parse(fileSize.toString());
    String fileSizeBeautified =
        homePageController.fileSizeBeautify(fileSizeInt);
    String sessKey;
    Socket socket;
    bool completed = false;

    await Future.delayed(Duration(milliseconds: 125));

    http.Response resp = await http.post(Uri.https(API_SERVER_ADDR, '/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'request': 'getReceiverPendingRequest',
          'authentication': sharedPrefs.getString('authKey')
        }));
    Map<String, dynamic> json = jsonDecode(resp.body);
    if (json["status"] == "success") {
      if (json["sender"] == senderName &&
          json["fileName"] == fileName &&
          json["fileSize"] == fileSizeInt) {
        sessKey = json["sessKey"];
        bool aborted = true;

        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Conferma ricezione file"),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(senderName + " vuole inviarti il seguente file:"),
                        Text("Nome: " + fileName),
                        Text("Dimensioni: " + fileSizeBeautified),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                  onPressed: () async {
                                    await http.post(
                                        Uri.https(API_SERVER_ADDR, '/'),
                                        headers: <String, String>{
                                          'Content-Type':
                                              'application/json; charset=UTF-8',
                                        },
                                        body: jsonEncode(<String, dynamic>{
                                          'request': 'setReceiverConfirmation',
                                          'authentication':
                                              sharedPrefs.getString('authKey'),
                                          'sessKey': json["sessKey"],
                                          'response': -1,
                                        }));
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  child: Text("Annulla")),
                              TextButton(
                                  onPressed: () async {
                                    resp = await http.post(
                                        Uri.https(API_SERVER_ADDR, '/'),
                                        headers: <String, String>{
                                          'Content-Type':
                                              'application/json; charset=UTF-8',
                                        },
                                        body: jsonEncode(<String, dynamic>{
                                          'request': 'setReceiverConfirmation',
                                          'authentication':
                                              sharedPrefs.getString('authKey'),
                                          'sessKey': json["sessKey"],
                                          'response': 1,
                                        }));
                                    json = jsonDecode(resp.body);
                                    if (json["status"] == "success") {
                                      aborted = false;
                                    }
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  },
                                  child: Text("Accetta"))
                            ])
                      ]));
            });
        if (!aborted) {
          Directory tempDir = await DownloadsPathProvider.downloadsDirectory;
          String tempPath = tempDir.path;
          String filePath = tempPath + '/' + fileName;
          int attempt = 2;
          while (await File(filePath).exists()) {
            filePath =
                tempPath + '/(' + (attempt++).toString() + ') ' + fileName;
          }
          double percentuale = 0;
          StateSetter _setDialogTitle,
              _setDialogContent,
              _setActionString,
              _setPercentualState;
          String dialogTitle = "Ricezione file in corso...";
          String actionString = "Annulla";
          Widget dialogContent = Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Puoi minimizzare l'app durante la ricezione del file."),
              Divider(color: const Color(0x5e5e5e)),
              Text("Nome: " + fileName),
              Text("Dimensioni: " + fileSizeBeautified),
              Text("Mittente: " + senderName),
              Text("Salvato in: " + filePath),
              new Padding(padding: const EdgeInsets.all(6)),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  _setPercentualState = setState;
                  return LinearPercentIndicator(
                    width: MediaQuery.of(context).size.width - 128,
                    animation: false,
                    lineHeight: 20.0,
                    percent: percentuale,
                    center: Text((percentuale * 100).toStringAsFixed(2) + "%"),
                    linearStrokeCap: LinearStrokeCap.roundAll,
                    progressColor: Colors.greenAccent,
                  );
                },
              )
            ],
          );
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        _setDialogTitle = setState;
                        return Text(dialogTitle);
                      },
                    ),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StatefulBuilder(
                            builder:
                                (BuildContext context, StateSetter setState) {
                              _setDialogContent = setState;
                              return dialogContent;
                            },
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(onPressed: () async {
                                  if (!completed) aborted = true;
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();
                                }, child: StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    _setActionString = setState;
                                    return Text(actionString);
                                  },
                                ))
                              ])
                        ]));
              });

          int receivedBytes = 0;
          bool watchdog = false;
          bool writeError = false;
          File writeFile = File(filePath);
          try {
            socket = await Socket.connect(
                json["tunnelHost"], json["tunnelPort"],
                timeout: Duration(seconds: 5));
            socket.setOption(SocketOption.tcpNoDelay, true);
            socket.add(utf8.encode(sessKey));

            var dataStream = writeFile.openWrite();
            int contentLength = 0, subVectIndex = 0;
            // ignore: avoid_init_to_null
            List<int> prevRecvd = null;
            socket.listen(
                (List<int> recv) {
                  watchdog = false;
                  if (prevRecvd == null) {
                    prevRecvd = recv;
                    contentLength = int.parse(utf8
                        .decode(prevRecvd.sublist(0, min(20, prevRecvd.length)),
                            allowMalformed: true)
                        .split('|')[0]);
                    subVectIndex =
                        utf8.encode(contentLength.toString() + '|').length;
                  } else
                    prevRecvd = prevRecvd + recv;
                  if (contentLength == prevRecvd.length - subVectIndex - 32) {
                    if (utf8.decode(
                            prevRecvd.sublist(subVectIndex, subVectIndex + 32),
                            allowMalformed: true) ==
                        md5
                            .convert(prevRecvd.sublist(subVectIndex + 32))
                            .toString()) {
                      receivedBytes += contentLength;
                      List<int> buff = prevRecvd.sublist(subVectIndex + 32);
                      dataStream.add(buff);
                      prevRecvd = null;
                      socket.add(utf8.encode('s' * 32));
                    } else {
                      prevRecvd = null;
                      socket.add(utf8.encode('n' * 32));
                    }
                  }
                },
                cancelOnError: true,
                onError: (error) {
                  if (!completed) {
                    aborted = true;
                    dialogTitle = "Operazione interrotta!";
                    dialogContent =
                        Text("Il trasferimento del file ?? stato annullato!");
                    _setDialogTitle(() {});
                    _setDialogContent(() {});
                  }
                });
            var watchdogStream =
                Stream<void>.periodic(Duration(seconds: 5), (_) {})
                    .listen((event) {
              if (watchdog) {
                try {
                  socket.close();
                } catch (e) {}
              } else
                watchdog = true;
            });
            var updatePercentual =
                Stream<void>.periodic(Duration(milliseconds: 250), (_) {})
                    .listen((event) {
              percentuale = receivedBytes.toDouble() / fileSizeInt.toDouble();
              _setPercentualState(() {});

              if (receivedBytes == fileSizeInt) {
                socket.close();
              }
            });

            await socket.done;
            dataStream.close();
            watchdogStream.cancel();
            updatePercentual.cancel();
            if (receivedBytes == fileSizeInt) {
              completed = true;
              dialogTitle = "Trasferimento completato!";
              dialogContent = Text(
                  "Il trasferimento del file ?? stato competato con successo!");
              actionString = "Chiudi";
              _setDialogTitle(() {});
              _setDialogContent(() {});
              _setActionString(() {});
            } else {
              if (writeError) {
                dialogTitle = "Operazione interrotta!";
                dialogContent = Text("Impossibile salvare il file in memoria!");
              } else {
                dialogTitle = "Operazione interrotta!";
                dialogContent =
                    Text("Il trasferimento del file ?? stato annullato!");
              }
              _setDialogTitle(() {});
              _setDialogContent(() {});
              try {
                await writeFile.delete();
              } catch (e) {}
            }
          } catch (e) {
            aborted = true;
            dialogTitle = "Operazione interrotta!";
            dialogContent =
                Text("Il trasferimento del file ?? stato annullato!");
            _setDialogTitle(() {});
            _setDialogContent(() {});
            try {
              await writeFile.delete();
            } catch (e) {}
          }
        }
      }
    } else {
      if (json["message"] == "NO_PENDING_REQUESTS") {
        AlertDialog err = AlertDialog(title: Text("La richiesta ?? scaduta!"));
        showDialog<void>(context: context, builder: (context) => err);
      }
    }
  }
}
