import 'package:flutter/material.dart';
import 'package:shareapp/controllers/set_profile_photo/set_profile_photo.dart';
import 'package:shareapp/home_page.dart';

class MySetProfilePhoto extends StatefulWidget {
  MySetProfilePhoto({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MySetProfilePhotoState createState() => _MySetProfilePhotoState();
}

class _MySetProfilePhotoState extends State<MySetProfilePhoto> {
  MySetProfilePhotoController mySetProfilePhotoController;

  @override
  void initState() {
    mySetProfilePhotoController = new MySetProfilePhotoController(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mySetProfilePhotoController.build();

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
                    image: mySetProfilePhotoController.pictureImage,
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
                        onPressed:
                            mySetProfilePhotoController.handleEliminaFoto,
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
                        onPressed: mySetProfilePhotoController.handleRandomFoto,
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
                        onPressed: mySetProfilePhotoController.handleUploadFoto,
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
                        onPressed: () async {
                          var res = await mySetProfilePhotoController
                              .handleSalvaFoto();
                          if (res == 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                            );
                          } else {
                            var err = AlertDialog(
                                title: Text(
                                    "C'è stato un errore nell'elaborazione della richiesta!"));
                            showDialog<void>(
                                context: context, builder: (context) => err);
                          }
                        },
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
}
