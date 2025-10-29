import 'dart:io';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/custome_field.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/home_viewmodel.dart';
import '../widgets/audio_waves.dart';

class UploadSongPage extends ConsumerStatefulWidget {
  const UploadSongPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends ConsumerState<UploadSongPage> {
  final songNameController = TextEditingController();
  final artistNameController = TextEditingController();
  Color selectedColor = Pallete.cardColor;
  File? selectedImage;
  PlatformFile? selectedAudio;
  final formKey = GlobalKey<FormState>();

  Future<void> selectAudio() async {
    FilePickerResult? pickedAudio = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'mp4', 'mhtml', 'wav', 'acc']
    );
    if(pickedAudio != null) {
      setState(() {
        selectedAudio = pickedAudio.files.first;
      });
    }
  }

  void selectImage() async {
    final pickedImage = await pickImage();
    if(pickedImage != null) {
      setState(() {
        selectedImage = pickedImage;
      });
    }
  }
  
  @override
  void dispose() {
    songNameController.dispose();
    artistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeViewmodelProvider.select((val) => val?.isLoading == true));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Song', textAlign: TextAlign.start,),
        actions: [
          IconButton(
            onPressed: () async {
              if(
                formKey.currentState!.validate() && 
                selectedAudio != null && 
                selectedImage != null
              ) {
              ref.watch(homeViewmodelProvider.notifier).uploadSong(
                selectedAudio: File(selectedAudio!.path!),
                selectedImage: selectedImage!, 
                songName: songNameController.text, 
                artist: artistNameController.text, 
                selectedColor: selectedColor
              );
              } else {
                showSnackBar(context, 'Missing fields');
              }
            }, 
            icon: const Icon(Icons.check),
          )
        ],
        backgroundColor: const Color.fromRGBO(28, 28, 28, 1),
      ),
      body: isLoading ? const Loader() : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: selectImage,
                  child: selectedImage!= null ? SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  ) : const DottedBorder(
                    options: RectDottedBorderOptions(
                      borderPadding: EdgeInsets.zero,
                      dashPattern: [10, 6],
                      color: Pallete.borderColor,
                      strokeCap: StrokeCap.round
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded),
                      
                          SizedBox(height: 8),
                      
                          Text('Select the thumbnail for your song')
                        ],
                      ),
                    ),
                  ),
                ),
            
                const SizedBox(height: 20),
            
                selectedAudio != null ? Column(
                  children: [
                    AudioWaves
                    (path: selectedAudio!.path!,
                    songUrl: 'null',
                    ),
                    IconButton(
                        onPressed: selectAudio,
                        icon: const Icon(Icons.repeat_rounded)
                    ),
                  ],
                )  :
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectAudio,
                    child: const Text('Select Audio', style: TextStyle(
                      fontSize: 20,
                    ),),
                  ),
                ),
                    
                const SizedBox(height: 12,),
                
                CustomeField(
                  hintText: 'Song Name', 
                  controller: songNameController
                ),
                    
                const SizedBox(height: 12,),
                
                CustomeField(
                  hintText: 'Artis Name', 
                  controller: artistNameController
                ),
                    
                const SizedBox(height: 12,),
                    
                ColorPicker(
                  pickersEnabled: const {
                    ColorPickerType.wheel: true,
                  },
                  color: selectedColor,
                  onColorChanged: (Color color) {
                    setState(() {
                      selectedColor = color;
                    });
                  }
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}