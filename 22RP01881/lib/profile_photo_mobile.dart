// import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String?> pickAndUploadImageMobile() async {
  // final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  // final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
  // if (image != null) {
  //   final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');
  //   final snapshot = await ref.putFile(File(image.path));
  //   return await snapshot.ref.getDownloadURL();
  // }
  return null;
} 