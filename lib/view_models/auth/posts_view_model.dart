import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/screens/mainscreen.dart';
import 'package:social_media_app/services/post_service.dart';
import 'package:social_media_app/services/user_service.dart';
import 'package:social_media_app/utils/constants.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostsViewModel extends ChangeNotifier {
  // Services
  UserService userService = UserService();
  PostService postService = PostService();

  // Keys
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Variables
  bool loading = false;
  String? username;
  File? mediaUrl;
  final picker = ImagePicker();
  String? location;
  Position? position;
  Placemark? placemark;
  String? bio;
  String? description;
  String? email;
  String? commentData;
  String? ownerId;
  String? userId;
  String? type;
  File? userDp;
  String? imgLink;
  bool edit = false;
  String? id;

  // Controllers
  TextEditingController locationTEC = TextEditingController();

  // Setters
  void setEdit(bool val) {
    edit = val;
    notifyListeners();
  }

  void setPost(PostModel? post) {
    if (post != null) {
      description = post.description;
      imgLink = post.mediaUrl;
      location = post.location;
      edit = true;
    } else {
      edit = false;
    }
    notifyListeners();
  }

  void setUsername(String val) {
    print('SetName $val');
    username = val;
    notifyListeners();
  }

  void setDescription(String val) {
    print('SetDescription $val');
    description = val;
    notifyListeners();
  }

  void setLocation(String val) {
    print('SetCountry $val');
    location = val;
    notifyListeners();
  }

  void setBio(String val) {
    print('SetBio $val');
    bio = val;
    notifyListeners();
  }

  // Functions

  Future<void> pickImage({bool camera = false, BuildContext? context}) async {
    loading = true;
    notifyListeners();
    try {
      final pickedFile = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Constants.lightAccent,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            IOSUiSettings(
              minimumAspectRatio: 1.0,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
          ],
        );
        if (croppedFile != null) {
          mediaUrl = File(croppedFile.path);
        }
      }
      loading = false;
    } catch (e) {
      loading = false;
      showInSnackBar('Cancelled', context);
    }
    notifyListeners();
  }

  Future<void> getLocation() async {
    loading = true;
    notifyListeners();
    LocationPermission permission = await Geolocator.checkPermission();
    print(permission.toString());
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission rPermission = await Geolocator.requestPermission();
      print(rPermission);
      await getLocation();
    } else {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position!.latitude,
        position!.longitude,
      );
      placemark = placemarks.isNotEmpty ? placemarks[0] : null;
      location = "${placemark?.locality ?? ''}, ${placemark?.country ?? ''}";
      locationTEC.text = location ?? '';
      print(location);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> uploadPosts(BuildContext context) async {
    try {
      loading = true;
      notifyListeners();
      await postService.uploadPost(mediaUrl!, location!, description!);
      resetPost();
      showInSnackBar('Uploaded successfully', context);
    } catch (e) {
      print(e);
      showInSnackBar('Failed to upload', context);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> uploadProfilePicture(BuildContext context) async {
    if (mediaUrl == null) {
      showInSnackBar('Please select an image', context);
      return;
    }

    try {
      loading = true;
      notifyListeners();
      await postService.uploadProfilePicture(
          mediaUrl!, FirebaseAuth.instance.currentUser!);
      Navigator.of(context)
          .pushReplacement(CupertinoPageRoute(builder: (_) => TabScreen()));
    } catch (e) {
      print(e);
      showInSnackBar('Failed to upload', context);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void resetPost() {
    mediaUrl = null;
    description = null;
    location = null;
    edit = false;
    notifyListeners();
  }

  void showInSnackBar(String value, BuildContext? context) {
    if (context != null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}
