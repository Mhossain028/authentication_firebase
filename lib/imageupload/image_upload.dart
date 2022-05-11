import 'dart:io';

import 'package:flutter/material.dart';
// image picker for picking the image
// firebase storage for uploading the image to firebase storage
// and cloud firestore for saving the url for uploaded image
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageUpload extends StatefulWidget {
  //User id to create a folter for a particular user
  String? userId;

  ImageUpload({Key? key, String? userId}) : super(key: key);

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  // some initialization code
  File? _image;
  final imagePicker = ImagePicker();
  String? downloadURL;

  //image picker for picking the image
  Future imagePickerMethod() async {
    //picking the file
    final pick = await imagePicker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pick != null) {
        _image = File(pick.path);
      } else {
        //showing a snackbar with error message
        showSnackBar("No File Selected", Duration(microseconds: 400));
      }
    });
  }

  //uploading the image to firebase storage and getting the download url
  //adding the url to cloud firestore
  Future uploadImage() async {
    final postID = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    Reference ref = FirebaseStorage.instance
        .ref()
        .child("${widget.userId}/images")
        .child("post_$postID");
    await ref.putFile(_image!);
    downloadURL = await ref.getDownloadURL();

    //uploading to cloudFire
    await firebaseFirestore
        .collection("users")
        .doc(widget.userId)
        .collection("images")
        .add({"downlpadURL": downloadURL});

    print(downloadURL);
  }

  //snackbar for showing the error message
  showSnackBar(String text, Duration d) {
    final snackBar = SnackBar(content: Text(text), duration: d);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          //for rounded rectangle clip
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 500,
              width: double.infinity,
              child: Column(
                children: [
                  const Text("Upload Image"),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _image == null
                                  ? const Center(
                                      child: Text("No Image Is Selected"),
                                    )
                                  : Image.file(_image!),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                imagePickerMethod();
                              },
                              child: const Text("Select Image"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                //upload only when the image has store values
                                if (_image != null) {
                                  uploadImage().whenComplete(() => showSnackBar(
                                      "Image Upload Successfuly",
                                      Duration(seconds: 2)));
                                } else {
                                  showSnackBar("No Image Is Selected",
                                      Duration(seconds: 2));
                                  print("No Image Is Selected");
                                }
                              },
                              child: const Text("Upload Image"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
