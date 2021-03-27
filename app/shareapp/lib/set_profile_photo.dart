import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'globals.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class SetProfilePhoto extends StatelessWidget {
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
        home: MySetProfilePhoto(title: 'ShareApp'));
  }
}

class MySetProfilePhoto extends StatefulWidget {
  MySetProfilePhoto({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MySetProfilePhotoState createState() => _MySetProfilePhotoState();
}

class _MySetProfilePhotoState extends State<MySetProfilePhoto> {
  String webImagePath;
  bool isGenericImage, isChanged = false, loadFromUrl = true;
  Uint8List imageBytes;
  ImageProvider pictureImage;

  Future getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        File _image = File(pickedFile.path);
        imageBytes = _image.readAsBytesSync();
        refreshImage();
      }
    });
  }

  void refreshImage() {
    if (loadFromUrl) {
      if (!isChanged) {
        webImagePath = 'https://' + API_SERVER_ADDR + '/avatars/generic.png';
        if (!isGenericImage) {
          webImagePath = 'https://' +
              API_SERVER_ADDR +
              '/avatars/' +
              sharedPrefs.getString('avatar');
        }
      }
      http.get(Uri.parse(webImagePath)).then((resp) {
        imageBytes = resp.bodyBytes;
        pictureImage = MemoryImage(imageBytes);
        setState(() {});
      });
    } else {
      pictureImage = MemoryImage(imageBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pictureImage == null) {
      // immagine vuota, per evitare che al primo avvio l'assert sul pictureImage != null fallisca
      pictureImage = MemoryImage(base64
          .decode("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"));
    }
    if (!isChanged) {
      try {
        if (sharedPrefs.getString('avatar').isEmpty)
          isGenericImage = true;
        else {
          if (sharedPrefs.getString('avatar') == 'generic.png')
            isGenericImage = true;
          else
            isGenericImage = false;
        }
      } catch (e) {
        isGenericImage = true;
      }
      refreshImage();
    }
    isChanged = true;

    return new Scaffold(
      appBar: new AppBar(title: new Text('Imposta immagine')),
      body: new Center(
        child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Text("Immagine corrente",
                  style: new TextStyle(
                      fontSize: 32,
                      color: const Color(0xFFffffff),
                      fontWeight: FontWeight.w700,
                      fontFamily: "Roboto")),
              new ClipOval(
                child: new Image(
                    image: pictureImage,
                    fit: BoxFit.fill,
                    width: 256,
                    height: 256),
              ),
              new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new TextButton(
                        key: null,
                        onPressed: handleEliminaFoto,
                        child: new Text("Elimina",
                            style: new TextStyle(fontSize: 12)),
                        style: ButtonStyle(
                            side: MaterialStateProperty.all(
                                BorderSide(width: 2, color: Colors.blueGrey)),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 20)))),
                    new TextButton(
                        key: null,
                        onPressed: handleRandomFoto,
                        child: new Text("Genera casualmente",
                            style: new TextStyle(fontSize: 12)),
                        style: ButtonStyle(
                            side: MaterialStateProperty.all(
                                BorderSide(width: 2, color: Colors.blueGrey)),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 20)))),
                    new TextButton(
                        key: null,
                        onPressed: handleUploadFoto,
                        child: new Text("Carica",
                            style: new TextStyle(fontSize: 12)),
                        style: ButtonStyle(
                            side: MaterialStateProperty.all(
                                BorderSide(width: 2, color: Colors.blueGrey)),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 20))))
                  ]),
              new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new TextButton(
                        key: null,
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()));
                        },
                        child: new Text(
                          "Annulla",
                          style: new TextStyle(fontSize: 20),
                        ),
                        style: ButtonStyle(
                            side: MaterialStateProperty.all(
                                BorderSide(width: 2, color: Colors.blueGrey)),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 50)))),
                    new TextButton(
                        key: null,
                        onPressed: handleSalvaFoto,
                        child: new Text("Salva",
                            style: new TextStyle(fontSize: 20)),
                        style: ButtonStyle(
                            side: MaterialStateProperty.all(
                                BorderSide(width: 2, color: Colors.blueGrey)),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 50))))
                  ])
            ]),
      ),
    );
  }

  void handleEliminaFoto() {
    isGenericImage = true;
    loadFromUrl = true;
    webImagePath = 'https://' + API_SERVER_ADDR + '/avatars/generic.png';
    refreshImage();
  }

  void handleRandomFoto() {
    isGenericImage = false;
    loadFromUrl = true;
    webImagePath =
        AVATAR_GENERATOR_SERVICE.replaceAll("[RANDOM]", randomAlphaNumeric(16));
    refreshImage();
  }

  void handleUploadFoto() {
    isGenericImage = false;
    loadFromUrl = false;
    getImage();
  }

  void handleSalvaFoto() {
    String imgToB64 = base64.encode(imageBytes);
    if (isGenericImage) {
      http
          .post(Uri.https(API_SERVER_ADDR, '/'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, dynamic>{
                'request': 'removeAvatar',
                'authentication': sharedPrefs.getString('authKey')
              }))
          .then((response) async {
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          sharedPrefs.setString('avatar', 'generic.png');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          var err = AlertDialog(
              title: Text(
                  "C'è stato un errore nell'elaborazione della richiesta!"));
          showDialog<void>(context: context, builder: (context) => err);
        }
      });
    } else {
      http
          .post(Uri.https(API_SERVER_ADDR, '/'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8'
              },
              body: jsonEncode(<String, dynamic>{
                'request': 'editAvatar',
                'authentication': sharedPrefs.getString('authKey'),
                'avatar': imgToB64
              }))
          .then((response) async {
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          sharedPrefs.setString('avatar', json['avatar']);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        } else {
          var err = AlertDialog(
              title: Text(
                  "C'è stato un errore nell'elaborazione della richiesta!"));
          showDialog<void>(context: context, builder: (context) => err);
        }
      });
    }
  }
}
