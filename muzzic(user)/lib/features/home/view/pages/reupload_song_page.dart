import 'dart:ffi';
import 'dart:io';
import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/custome_field.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/view/pages/home_page.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song_model.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../widgets/audio_waves.dart';

class UploadSongPageDemo extends ConsumerStatefulWidget {
  final SongModel songGetter;

  const UploadSongPageDemo({
    super.key,
    required this.songGetter
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UploadSongPageDemoState();
}

class _UploadSongPageDemoState extends ConsumerState<UploadSongPageDemo> {

  var songNameController = TextEditingController();
  var artistNameController = TextEditingController();
  Color? selectedColor = Pallete.cardColor;
  File? selectedImage;
  PlatformFile? selectedAudio;
  String? previousAudio;
  bool isSaving = false;
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
  void initState() {
    // TODO: implement initState
    songNameController.text = widget.songGetter.song_name;
    artistNameController.text = widget.songGetter.artist;
    selectedColor = hexToRgb(widget.songGetter.hex_code);
    _populateFields();
    super.initState();
  }

  void _populateFields() {
    songNameController.text = widget.songGetter.song_name;
    artistNameController.text = widget.songGetter.artist;
    selectedImage = null;
    selectedAudio = null;
    selectedColor  = hexToRgb(widget.songGetter.hex_code);
  }

  @override
  void didUpdateWidget(covariant UploadSongPageDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songGetter.id != widget.songGetter.id) {
      _populateFields();
    }
  }

  Future<void> _saveChanges() async {
    if (isSaving) return;
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    final currentUser = ref.read(currentUserNotifierProvider);
    await ref.read(homeViewmodelProvider.notifier).editSong(
      token: currentUser!.token,
      id: widget.songGetter.id,
      selectedAudio: selectedAudio != null ? File(selectedAudio!.path!) : null,
      selectedImage: selectedImage,
      songName: songNameController.text.isNotEmpty ? songNameController.text : null,
      artist: artistNameController.text.isNotEmpty ? artistNameController.text : null,
      selectedColor: selectedColor,
    );

    setState(() {
      isSaving = false;
    });

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()
          )
      );
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

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HomePage())
              );
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
        titleSpacing: 12,
        title: const Text(
          'Upload Song',
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color.fromRGBO(28, 28, 28, 1),
      ),
      body: Form(
        key: formKey,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: GestureDetector(
                        onTap: selectImage,
                        child: selectedImage != null ? SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                        ) :  SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(widget.songGetter.thumbnail_url),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(10)
                            ),
                          ),
                        )
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 150,
                          child: selectedAudio != null ? AudioWaves(
                            songUrl: 'null',
                            path: selectedAudio!.path!,
                          ) : AudioWaves(
                            songUrl: widget.songGetter.song_url,
                            path: 'null',
                          ),
                        ),
                        IconButton(
                            onPressed: selectAudio,
                            icon: const Icon(Icons.repeat_rounded)
                        ),
                      ],
                    ),
                  )
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: CustomeField(
                      hintText: 'Song Name',
                      controller: songNameController,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 22,
                    )
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: CustomeField(
                      hintText: 'Artist Name',
                      controller: artistNameController,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: SizedBox(
                      child: ColorPicker(
                          pickersEnabled: const {
                            ColorPickerType.wheel: true,
                          },
                          color: hexToRgb(widget.songGetter.hex_code),
                          onColorChanged: (Color color) {
                            setState(() {
                              selectedColor = color;
                            });
                          }),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                  ),
                )
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 80,
                color: Pallete.cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: ElevatedButton(

                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.deepPurple)
                    ),

                    onPressed: isSaving ? null : _saveChanges,

                    child: isSaving
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Center(
                      child: Text("Save the changes", style: TextStyle(
                        color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                      ),),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}