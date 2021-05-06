import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:shareapp/globals.dart';
import 'package:http/http.dart' as http;

class MySetProfilePhotoController {
  State _mySetProfilePhotoState;
  String webImagePath;
  bool isGenericImage, isChanged = false, loadFromUrl = true;
  Uint8List imageBytes;
  ImageProvider pictureImage;

  MySetProfilePhotoController(State mySetProfilePhotoState) {
    _mySetProfilePhotoState = mySetProfilePhotoState;
  }

  Future getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    _mySetProfilePhotoState.setState(() {
      if (pickedFile != null) {
        File _image = File(pickedFile.path);
        imageBytes = _image.readAsBytesSync();
        refreshImage();
      }
    });
  }

  void build() {
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
  }

  void refreshImage() async {
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
      var resp = await http.get(Uri.parse(webImagePath));
      imageBytes = resp.bodyBytes;
      pictureImage = MemoryImage(imageBytes);
      _mySetProfilePhotoState.setState(() {});
    } else {
      pictureImage = MemoryImage(imageBytes);
    }
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

  Future<int> handleSalvaFoto() async {
    String imgToB64 = base64.encode(imageBytes);
    if (isGenericImage) {
      var response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'removeAvatar',
            'authentication': sharedPrefs.getString('authKey')
          }));
      Map<String, dynamic> json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        sharedPrefs.setString('avatar', 'generic.png');
        return 1;
      } else {
        return -1;
      }
    } else {
      var response = await http.post(Uri.https(API_SERVER_ADDR, '/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode(<String, dynamic>{
            'request': 'editAvatar',
            'authentication': sharedPrefs.getString('authKey'),
            'avatar': imgToB64
          }));
      Map<String, dynamic> json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        sharedPrefs.setString('avatar', json['avatar']);
        return 1;
      } else {
        return -1;
      }
    }
  }
}
