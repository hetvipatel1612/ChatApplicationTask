import 'dart:async';
import 'dart:io';

import 'package:chatapplication/constants/firestore_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/color_constants.dart';
import '../models/user_chat.dart';
import '../providers/setting_provider.dart';
import '../widgets/loading_view.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';

  bool isLoading = false;
  File? avatarImageFile;
  late final SettingProvider settingProvider = context.read<SettingProvider>();

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingProvider.getPref(FirestoreConstants.id) ?? "";
      nickname = settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
    });

    controllerNickname = TextEditingController(text: nickname);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
      return null;
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickname: nickname,
        aboutMe: aboutMe,
      );
      settingProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Upload success");
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickname: nickname,
      aboutMe: aboutMe,
    );
    settingProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await settingProvider.setPref(FirestoreConstants.nickname, nickname);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Avatar
                CupertinoButton(
                  onPressed: getImage,
                  child: Container(
                    margin: EdgeInsets.all(20),
                    child: avatarImageFile == null
                        ? photoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(45),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, object, stackTrace) {
                                    return Icon(
                                      Icons.account_circle,
                                      size: 90,
                                      color: ColorConstants.greyColor,
                                    );
                                  },
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 90,
                                      height: 90,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: ColorConstants.themeColor,
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 90,
                                color: ColorConstants.greyColor,
                              )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: Image.file(
                              avatarImageFile!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),

                // Input
                Column(
                  children: <Widget>[
                    // Username

                    Container(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextFormField(
                          validator: (val) => val != null && val.isNotEmpty
                              ? null
                              : 'Required Field',
                          decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.person, color: Colors.blue),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              hintText: 'eg. Happy Singh',
                              label: const Text('Nikname ')),
                          // decoration: InputDecoration(
                          //   hintText: 'Sweetie',
                          //   contentPadding: EdgeInsets.all(5),
                          //   hintStyle:
                          //       TextStyle(color: ColorConstants.greyColor),
                          // ),
                          controller: controllerNickname,
                          onChanged: (value) {
                            nickname = value;
                          },
                          focusNode: focusNodeNickname,
                        ),
                      ),
                      margin: EdgeInsets.only(left: 30, right: 30),
                    ),

                    // About me
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextFormField(
                          validator: (val) => val != null && val.isNotEmpty
                              ? null
                              : 'Required Field',
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.info_outline,
                                  color: Colors.blue),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              hintText: 'eg. Feeling Happy',
                              label: const Text('About')),
                          controller: controllerAboutMe,
                          onChanged: (value) {
                            aboutMe = value;
                          },
                          focusNode: focusNodeAboutMe,
                        ),
                      ),
                      margin: EdgeInsets.only(left: 30, right: 30),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),

                // Button
                Container(
                  margin: EdgeInsets.only(top: 50, bottom: 50),
                  child: TextButton(
                    onPressed: handleUpdateData,
                    child: Text(
                      'Update Data',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          ColorConstants.primaryColor),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.fromLTRB(30, 10, 30, 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading
          Positioned(child: isLoading ? LoadingView() : SizedBox.shrink()),
        ],
      ),
    );
  }
}
