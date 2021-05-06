import 'dart:async';
import 'dart:convert';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shareapp/globals.dart';
import 'package:sms_autofill/sms_autofill.dart';

class HomePageController {
  String myPhoneNumber;

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

  void getMyPhoneNumber() {
    try {
      myPhoneNumber = sharedPrefs.getString('phoneNumber');
    } catch (e) {
      myPhoneNumber = null;
    }
  }

  Future<int> addContact(String usernameToAdd) async {
    if (usernameToAdd.isNotEmpty) {
      var response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'addContact',
            'authentication': sharedPrefs.getString('authKey'),
            'username': usernameToAdd
          }));
      Map<String, dynamic> json = jsonDecode(response.body);
      if (json['status'] == 'success')
        return 0;
      else {
        if (json['message'] == 'USER_NOT_FOUND')
          return -1;
        else if (json['message'] == 'USERS_ALREADY_CONNECTED') return -2;
      }
    }
    return -3;
  }

  Future<int> deleteContact(int id) async {
    var response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'request': 'removeContact',
          'authentication': sharedPrefs.getString('authKey'),
          'user_ID': id
        }));

    Map<String, dynamic> json = jsonDecode(response.body);
    if (json['status'] == 'success') return 0;
    return -1;
  }

  void startFirebaseListener(Function fileReceiveHandler) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null)
        fileReceiveHandler(message.data['fileName'],
            int.parse(message.data['fileSize']), message.data['senderName']);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null)
        fileReceiveHandler(message.data['fileName'],
            int.parse(message.data['fileSize']), message.data['senderName']);
    });
    FirebaseMessaging.instance.getToken().then((firebaseToken) async {
      await sharedPrefs.setString('firebaseToken', firebaseToken);
      await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'syncFirebaseToken',
            'authentication': sharedPrefs.getString('authKey'),
            'firebaseToken': firebaseToken,
          }));
    });
  }

  Future<void> doLogout() async {
    await sharedPrefs.remove('authKey');
    await FirebaseMessaging.instance.deleteToken();
  }

  Future<int> rubricaSync({bool askForNumber = true}) async {
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
        return 0;
      } else
        return -1;
    } else
      return -2;
  }
}
