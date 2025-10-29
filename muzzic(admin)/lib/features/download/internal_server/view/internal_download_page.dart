import 'dart:convert';
import 'dart:io';
import 'package:client/core/constants/server_constants.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/download/internal_server/models/data.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../../core/providers/current_song_notifier.dart';
import '../../../../core/theme/app_pallet.dart';
import 'dart:io' show Directory, Platform, File;
import 'package:client/core/widgets/custome_field.dart';
import '../../../../core/utils.dart' show showSnackBar, AppBanner2;
import '../../../auth/view/pages/signup_page.dart';
import '../models/audio_formats.dart';

class InternalDownloadPage extends ConsumerStatefulWidget {
  const InternalDownloadPage({super.key});

  @override
  ConsumerState<InternalDownloadPage> createState() => _InternalDownloadPageState();
}

class _InternalDownloadPageState extends ConsumerState<InternalDownloadPage> {
  final TextEditingController _textEditingController = TextEditingController();

  bool isLoading = false;

  Future<void> deleteDownloadedSong(String songId) async {
    final box = Hive.box<SongModel>('offlineSongs');
    final song = box.get(songId);

    if (song != null) {

      final audioPath = File(song.localAudioPath!);
      if (audioPath.existsSync()) audioPath.deleteSync();

      final thumbnailPath = File(song.localThumbnailPath!);
      if (thumbnailPath.existsSync()) thumbnailPath.deleteSync();

      await box.delete(songId);
    }
  }

  Future<DataModel> fetchFormats(String url) async {
    final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/download/formats/audio?url=$url')
    );

    if (response.statusCode == 200) {
      final json = DataModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      return json;
    } else {
      throw Exception("Failed to fetch the formats: ${response.statusCode}");
    }
  }

  // This downloadAudio functions calls the backend to download audio from yt.dlp
  Future<String> downloadAudio({
    required String audioUrl,
    required String formatId,
    required String title,
    required String ext,
  }) async {
    final uri =
        Uri.parse('${ServerConstants.serverURL}/download/audio?url=$audioUrl&format_id=$formatId');

    final response = http.Request('Get', uri);
    final streamedResponse = await response.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception("Download failed with status ${streamedResponse.statusCode}");
    }

    final safeTitle = title.replaceAll(RegExp(r'[\/\\:*?"<>|]'), '_');
    final fileName = "$safeTitle.mp3";

    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = (await getExternalStorageDirectory())!;
      }
    } else {
      dir = (await getApplicationDocumentsDirectory());
    }
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    // Create file sink & stream data
    final sink = file.openWrite();
    await streamedResponse.stream.pipe(sink);
    await sink.close();

    return filePath;
  }

  void _formatShowBottomSheet (BuildContext context, DataModel data, String audioUrl) {
    AudioFormat? selectedFormat;
    bool downloading = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (content, setModelState) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    left: 12,
                    right: 12,
                    top: 12
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: ListView.separated(
                        separatorBuilder: (_, _) => const Divider(height: 0),
                        itemCount: data.audioFormats.length,
                        itemBuilder: (context, index) {
                          final format = data.audioFormats[index];
                          final isSelected = selectedFormat == format;
                          return Column(
                            children: [
                              Card(
                                child: Padding(
                                    padding: EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text.rich(
                                        TextSpan(text: format.formatId)
                                      ),
                                      Text.rich(
                                          TextSpan(text: format.fileSizeMb.toString())
                                      ),
                                      Text.rich(
                                        TextSpan(text: format.ext.toUpperCase())
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            setModelState(() =>
                                            selectedFormat = format
                                            );
                                          },
                                          icon: isSelected
                                              ? const Icon(Icons.check_circle)
                                              : const Icon(Icons.circle_outlined),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12,),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        icon: downloading ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(),
                        ) : const Icon(Icons.download),
                        label: Text(downloading ? "Downloading..." : "Download selected format"),
                        onPressed: selectedFormat == null || downloading
                            ? null
                            : () async {
                          setModelState (() => downloading = true);
                          try {
                            final savePath = await downloadAudio(
                              formatId: selectedFormat!.formatId,
                              audioUrl: audioUrl,
                              title: data.title,
                              ext: selectedFormat!.ext,
                            );
                            setState(() => downloading = false);
                            Navigator.pop(context);
                            AppBanner2.show(
                                context,
                                title: "Audio Downloaded",
                                message: "Your select file is downloaded successfully and stored in downloads file",
                                // contentType: ContentType.success,
                                inMaterialBanner: false,
                              contentType: ContentType.success
                            );
                          } catch(e) {
                            setState(() => downloading = false);
                            showSnackBar(context, "Download failed: $e");
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8,)
                  ],
                ),
              );
            },
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final box = Hive.box<SongModel>('offlineSongs');

    return Scaffold(
      appBar: AppBar(
        title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text("Download Page"),
              ElevatedButton(
                  onPressed: () async {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(
                        builder: (context) => const SignupPage()
                    )
                    );
                    await ref.watch(authViewmodelProvider.notifier).logOut();
                  },
                  child: const Row(
                    children: [
                      Text("Sign Out"),
                      Icon(Icons.logout),
                    ],
                  )
              ),
            ],
          ),
        ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadiusGeometry.all(Radius.circular(20)),
                    color: Color.fromRGBO(14, 14, 14, 1),
                  ),
                  // margin: const EdgeInsets.all(18),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      CustomeField(
                          hintText: 'Paste the link',
                          controller: _textEditingController
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            final url = _textEditingController.text.trim();
                            if (url.isEmpty) {
                              showSnackBar(context, "Please enter the url.");
                              return;
                            }

                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final data = await fetchFormats(url);
                              setState(() {
                                isLoading = false;
                              });
                              _formatShowBottomSheet(
                                  context,
                                  data,
                                  url
                              );
                            } catch(e) {
                              setState(() {
                                isLoading = false;
                              });
                              showSnackBar(context, "Failed to fetch the song: $e");
                            }
                          },
                          child: const Text('Audio Download', style: TextStyle(
                            fontSize: 20,
                          ),),
                        ),
                      ),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 44,
                      //   child: ElevatedButton(
                      //     onPressed: () {
                      //       Navigator.push(
                      //           context, MaterialPageRoute(
                      //           builder: (context) => AudioFormats(
                      //               audioURL: _textEditingController.text
                      //           )
                      //       )
                      //       );
                      //     },
                      //     child: const Text('Video Download', style: TextStyle(
                      //       fontSize: 20,
                      //     ),),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),

            ValueListenableBuilder<Box<SongModel>>(
              valueListenable: box.listenable(),
              builder: (context, Box<SongModel> songsBox, _) {
                final downloadedSongs = songsBox.values.where((song) => song.isDownload).toList();

                if (songsBox.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Text('No songs saved to downloads'),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                            childCount: downloadedSongs.length,
                                (context, index) {
                              final song = downloadedSongs[index];
                              return Card(
                                // margin: EdgeInsets.all(8),
                                elevation: 0,
                                color: Pallete.cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(leading: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Pallete.cardColor,
                                    backgroundImage: FileImage(File(song.localThumbnailPath!)),
                                  ),
                                    title: Text(
                                      song.song_name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700
                                      ),
                                    ),
                                    onTap: () {
                                      ref
                                          .watch(
                                          currentSongNotifierProvider.notifier)
                                          .updateSong(song);
                                    },
                                    trailing: PopupMenuButton(
                                        color: Pallete.cardColor,
                                        shadowColor: Pallete.gradient3,
                                        itemBuilder: (BuildContext context) =>
                                        [
                                          PopupMenuItem(
                                              onTap: () async {
                                                deleteDownloadedSong(song.id);
                                              },
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.remove),
                                                  Text('Remove from downloads'),
                                                ],
                                              )
                                          ),
                                        ]
                                    ),
                                  ),
                                ),
                              );
                            }
                        ),
                    ),
                );
              },
            )
          ]
        ),
      ),
    );
  }
}
