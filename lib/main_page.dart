import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internal_app/sync_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'popup.dart';

class MainPage extends StatefulWidget{
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>{

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source, String groupName) async{
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null){
      File imageFile = File(pickedFile.path);
      
      setState(() {
        image = imageFile;
      });
      
      await uploadImage(imageFile, groupName);
    }
  }


  File? image;
  bool isUploading = false;
  final picker = ImagePicker();

  final StorageService _storageService = StorageService();

  Future<void> uploadImage(File imageFile, String groupName) async{
    setState(() => isUploading = true);

    Popup.show(context, "Wysyłanie zdjęcia do chmury");

    String? url = await _storageService.uploadImage(imageFile, groupName);

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
  



  List<String> groups = [];
  bool isLoading = true;

  Future<void> loadGroups() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      groups = prefs.getStringList('user_groups') ?? [];
      isLoading = false;
    });
  }

  Future<void> saveGroups() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_groups', groups);
  }

  void addGroup(){
    showDialog(
      context: context,
      builder: (context){
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Dodaj nową grupę'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nazwa grupy'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj')
            ),
            ElevatedButton(
              onPressed: () async{
                if(controller.text.isNotEmpty){
                  setState((){
                    groups.add(controller.text);
                  });
                  await saveGroups();
                  Navigator.pop(context);
                }
              },
              child: const Text('Dodaj'),
            )
          ],
        );
      }
    );
  }


 
void addPhotoToGroup(String groupName){
  pickImage(ImageSource.camera, groupName);
}

void viewGroupGallery(String groupName){

}

Future<void> deleteGroup(int index) async{
  setState((){
    groups.removeAt(index);
  });
  await saveGroups();
}

@override
Widget build(BuildContext context){
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Center(
        child: TextButton.icon(
          onPressed: addGroup,
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text(
            'Dodaj grupę',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )
          )
        )
      )
    ),

    body: groups.isEmpty
    ?const Center(child: Text("Dodaj pierwszą grupę")):
    ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey,
      ),
      itemBuilder: (context, index){
        final groupName = groups[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),

          onTap: () => addPhotoToGroup(groupName),
          title: Text(
            groupName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            )
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.photo_library_outlined,
                  size: 28,
                ),
                onPressed: () => viewGroupGallery(groupName),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 28,
                ),
                onPressed: () => deleteGroup(index),
              )
            ],
          ),
        );
      },
    )
  );
}


final SyncHandler _syncHandler = SyncHandler();
@override
  void initState() {
    super.initState();
    loadGroups();

    _syncHandler.syncPhotos(context, 'test');
  }


}
