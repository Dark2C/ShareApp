import '../../home_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../set_profile_photo.dart';
import '../../controllers/main/main.dart';

class MyLoginForm extends StatefulWidget {
  MyLoginForm({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyLoginFormState createState() => _MyLoginFormState();
}

class _MyLoginFormState extends State<MyLoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  MainController mainController;

  @override
  void initState() {
    mainController = new MainController(_username, _password);
    super.initState();
  }

//Permission.storage.request();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: mainController.init(),
        builder: (context, snapshot) {
          if (!mainController.isLogged()) return loginForm();
          return FutureBuilder(
              future: Permission.storage.request(),
              builder: (context, AsyncSnapshot<PermissionStatus> snapshot) {
                if (snapshot.data.isGranted) return HomePage();
                return Center(
                    child: Text(
                        "L'app ha bisogno di accedere ai file per funzionare!",
                        textAlign: TextAlign.center));
              });
        });
  }

  Widget loginForm() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Benvenuto',
                style: new TextStyle(
                    fontSize: 48,
                    color: const Color(0xFFffffff),
                    fontWeight: FontWeight.w900,
                    fontFamily: "Roboto")),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: TextFormField(
                controller: _username,
                decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'Username',
                    contentPadding: EdgeInsets.all(20.0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: TextFormField(
                controller: _password,
                decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'Password',
                    contentPadding: EdgeInsets.all(20.0)),
                obscureText: true,
                autocorrect: false,
              ),
            ),
            new Padding(padding: const EdgeInsets.all(6)),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: TextButton(
                    onPressed: handleLogin,
                    child: Text("Login", style: new TextStyle(fontSize: 24)),
                    style: ButtonStyle(
                        side: MaterialStateProperty.all(
                            BorderSide(width: 2, color: Colors.blueGrey)),
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                            vertical: 20, horizontal: 50))))),
            Text('- o -',
                style: new TextStyle(
                    fontSize: 24,
                    color: const Color(0xFFdddddd),
                    fontFamily: "Roboto")),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                child: TextButton(
                    onPressed: handleRegistration,
                    child: Text("Registrati",
                        style: new TextStyle(fontSize: 24.0)),
                    style: ButtonStyle(
                        side: MaterialStateProperty.all(
                            BorderSide(width: 2, color: Colors.blueGrey)),
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                            vertical: 20, horizontal: 50))))),
          ],
        ),
      ),
    );
  }

  void handleLogin() async {
    var res = await mainController.handleLogin();
    if (res == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    } else if (res == -1) {
      AlertDialog err = AlertDialog(
          title: Text('I campi username e password sono obbligatori!'));
      showDialog<void>(context: context, builder: (context) => err);
    } else if (res == -2) {
      AlertDialog err =
          AlertDialog(title: Text("Utente inesistente o password non valida!"));
      showDialog<void>(context: context, builder: (context) => err);
    }
  }

  void handleRegistration() async {
    var res = await mainController.handleRegistration();
    if (res == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SetProfilePhoto()));
    } else if (res == -1) {
      AlertDialog err = AlertDialog(
          title: Text('I campi username e password sono obbligatori!'));
      showDialog<void>(context: context, builder: (context) => err);
    } else if (res == -2) {
      AlertDialog err =
          AlertDialog(title: Text("Il nome utente indicato è già esistente!"));
      showDialog<void>(context: context, builder: (context) => err);
    }
  }
}
