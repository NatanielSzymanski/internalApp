import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internal_app/sync_handler.dart';
import 'storage_service.dart';
import 'popup.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async{
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null){
      File imageFile = File(pickedFile.path);
      
      setState(() {
        image = imageFile;
      });
      
      await uploadImage(imageFile);
    }
  }


  File? image;
  bool isUploading = false;
  final picker = ImagePicker();

  final StorageService _storageService = StorageService();

  Future<void> uploadImage(File imageFile) async{
    setState(() => isUploading = true);

    Popup.show(context, "Wysyłanie zdjęcia do chmury");

    String? url = await _storageService.uploadImage(imageFile, 'test');

    setState(() => isUploading = false);
    
    Popup.hide();
    if(url != null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded to cloud'))
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed'))
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height:300,
              width: 300,
              child: image != null?
                Image.file(image!):
                const Center(child:Text('No image selected')),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.camera), 
                  child: const Text("Camera"),
                ),

                ElevatedButton(
                  onPressed: () => _syncHandler.syncPhotos(context, 'test'), 
                  child: const Text("Refresh"),
                ),
              ],
              )
          ],
        )
      )
    );
  }

  final SyncHandler _syncHandler = SyncHandler();

  @override
  void initState() {
    super.initState();

    _syncHandler.syncPhotos(context, 'test');
  }
}