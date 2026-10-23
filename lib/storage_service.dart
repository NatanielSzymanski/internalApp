import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final String cloudName = 'n1opkixt';
  final String uploadPreset = 'internalCamera';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadImage(File imageFile, String groupId) async{
    
    final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

    CloudinaryResponse response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image)
    );
    
    String downloadUrl = response.secureUrl;
    String imageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('images')
      .doc(imageId)
      .set({
        'imageId': imageId,
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp()
      });

    return downloadUrl;

  }
}