import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'popup.dart';
import 'package:cloudinary/cloudinary.dart';

class SyncHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio();

  final cloudinary = Cloudinary.signedConfig(
    cloudName: 'n1opkixt',
    apiKey: '513232949115765',
    apiSecret: "AqVC4uaLPCvwZi9eRKYvYQbI5pU"
  );

  bool isDepreciated(dynamic createdAt, String imageId){
    
    DateTime? createdStamp;

    if(createdAt is Timestamp){
      createdStamp = createdAt.toDate();
    }else if(createdAt is String){
      createdStamp = DateTime.tryParse(createdAt);
    }

    if(createdStamp == null) return false;

    final difference = DateTime.now().difference(createdStamp);

    if(difference.inHours >= 48){
      return true;
    }

    return false;

  }

  String getPublicId(String url){
    final uri = Uri.parse(url);

    final fileName = uri.pathSegments.last;
    final publicId = fileName.split('.').first;
    return publicId;
  }

  Future<void> deleteFromCloudinary(String imageUrl) async{
    final String publicId = getPublicId(imageUrl);
    
    await cloudinary.destroy(
      publicId,
      resourceType: CloudinaryResourceType.image,
      invalidate: true
    );

  }

  Future<void> syncPhotos(BuildContext context, groupId) async {
    final hasAccess = await Gal.hasAccess();
    if(hasAccess == false){
      await Gal.requestAccess();
    }

    final prefs = await SharedPreferences.getInstance();
    
    final List<String> savedGroups = prefs.getStringList('user_groups') ?? [];
    final List<String> syncedIds = prefs.getStringList('synced_photos') ?? [];

    final tempDir = await getTemporaryDirectory();
    int totalDownloaded = 0;

    for(String groupName in savedGroups){
      Popup.show(context, 'Sprawdzanie dostępności zdjęć');

      final querySnapshot = await _firestore
        .collection('groups')
        .doc(groupName)
        .collection('images')
        .get();

      

      for (var doc in querySnapshot.docs){
        Popup.show(context, "fonwajdnwajg");
        final data = doc.data();
        final String imageId = data['imageId'] ?? doc.id;
        final String imageUrl = data['url'] ?? '';
        final String createdAt = data['createdAt'];

        Popup.show(context, 'id:$imageId url:$imageUrl createdAt:$createdAt');
        //print('id:$imageId url:$imageUrl createdAt:$createdAt');

        /*if(isDepreciated(createdAt, imageId)){
          print("it is depreciated");
          await deleteFromCloudinary(imageUrl);
          print("deleted from cloudinary");

          await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('images')
            .doc(doc.id)
            .delete();

          if(syncedIds.contains(imageId)){
            syncedIds.remove(imageId);
            await prefs.setStringList('synced_photos', syncedIds);
          }

          print("usunelo sie wasyzsto");
          continue;
        }*/

        if(imageUrl.isEmpty) continue;

        if(syncedIds.contains(imageId)){
          continue;
        }

        totalDownloaded++;
        Popup.show(context, 'Pobieranie nowych zdjęć');
        
        final String tempPath = '${tempDir.path}/${imageId}.jpg';
        final tempFile = File(tempPath);

        print('Pobieranie pliku: $imageId z $imageUrl');
        await _dio.download(imageUrl, tempPath);

        await Gal.putImage(tempPath, album: 'InternalCamera');

        if(await tempFile.exists()){
          await tempFile.delete();
        }

        syncedIds.add(imageId);
        await prefs.setStringList('synced_photos', syncedIds);
      }
    }
      if(totalDownloaded > 0){
        Popup.show(context, 'Pobrano $totalDownloaded nowych zdjęć');
      }else{
        Popup.show(context, 'Brak nowych zdjęć');

      }
      //Checkmark popup
      await Future.delayed(const Duration(seconds: 2));
      Popup.hide();
  }
}