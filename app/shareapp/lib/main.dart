import 'dart:convert';
import 'globals.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'set_profile_photo.dart';

void main() {
  runApp(FirstScreen());
}

class FirstScreen extends StatelessWidget {
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
        home: MyLoginForm(title: 'ShareApp'));
  }
}

class MyLoginForm extends StatefulWidget {
  MyLoginForm({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyLoginFormState createState() => _MyLoginFormState();
}

class _MyLoginFormState extends State<MyLoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isLogged = false;

  Future<void> _getPrefs() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  Future<bool> checkLogin() async {
    try {
      if (sharedPrefs.getString('authKey').isEmpty) return false;
    } catch (e) {
      return false;
    }

    http.Response resp = await http.post(Uri.https(API_SERVER_ADDR, '/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'request': 'getCurrentUser',
          'authentication': sharedPrefs.getString('authKey'),
        }));
    Map<String, dynamic> json = jsonDecode(resp.body);
    if (json['status'] == 'success') {
      await sharedPrefs.setInt('user_ID', json['user_ID']);
      await sharedPrefs.setString('username', json['username']);
      await sharedPrefs.setString('avatar', json['avatar']);
      return true;
    } else if (json['status'] == 'error') {
      try {
        await sharedPrefs.remove('authKey');
      } catch (e) {}
      try {
        await sharedPrefs.remove('user_ID');
      } catch (e) {}
      try {
        await sharedPrefs.remove('username');
      } catch (e) {}
      try {
        await sharedPrefs.remove('avatar');
      } catch (e) {}
    }
    return false;
  }

  Future<void> init() async {
    await _getPrefs();
    _isLogged = await checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init(),
      builder: (context, snapshot) {
        if (!_isLogged) return loginForm();
        return HomePage();
      },
    );
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

  bool areFieldsFilled() {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      AlertDialog err = AlertDialog(
          title: Text('I campi username e password sono obbligatori!'));
      showDialog<void>(context: context, builder: (context) => err);
    }
    return (!(_username.text.isEmpty || _password.text.isEmpty));
  }

  void handleLogin() {
    if (areFieldsFilled()) {
      http
          .post(Uri.https(API_SERVER_ADDR, '/'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, dynamic>{
                'request': 'login',
                'authentication': {
                  'username': _username.text,
                  'password': _password.text
                },
              }))
          .then((response) async {
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          await sharedPrefs.setString('authKey', json['authKey']);
          checkLogin().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          });
        } else {
          AlertDialog err = AlertDialog(
              title: Text("Utente inesistente o password non valida!"));
          showDialog<void>(context: context, builder: (context) => err);
        }
      });
    }
  }

  void handleRegistration() {
    if (areFieldsFilled()) {
      http
          .post(Uri.https(API_SERVER_ADDR, '/'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8'
              },
              body: jsonEncode(<String, dynamic>{
                'request': 'register',
                'authentication': {
                  'username': _username.text,
                  'password': _password.text
                },
              }))
          .then((response) async {
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          sharedPrefs.setString('avatar', 'generic');
          sharedPrefs.setString('authKey', json['authKey']);
          checkLogin().then((value) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => SetProfilePhoto()));
          });
        } else {
          AlertDialog err = AlertDialog(
              title: Text("Il nome utente indicato è già esistente!"));
          showDialog<void>(context: context, builder: (context) => err);
        }
      });
    }
  }
}
