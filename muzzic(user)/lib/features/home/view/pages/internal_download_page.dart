import 'dart:convert';
import 'dart:io';
import 'package:client/core/constants/server_constants.dart';
import 'package:client/core/providers/playlist_controller.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_pallet.dart';
import 'dart:io' show Directory, Platform, File;
import 'package:client/core/widgets/custome_field.dart';
import '../../../../core/utils.dart' show showSnackBar, AppBanner2;
import '../../../auth/view/pages/signup_page.dart';

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

  Future<String> downloadVideo({
    required String videoUrl,
    required String title,
  }) async {
    final uri = Uri.parse('${ServerConstants.serverURL}/download/video?url=$videoUrl');

    final request = http.Request('GET', uri);
    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception("Download failed with status ${streamedResponse.statusCode}");
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeTitle = title.replaceAll(RegExp(r'[\/\\:*?"<>|]'), '_');
    final fileName = "$safeTitle-$timestamp.mp4";

    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = (await getExternalStorageDirectory())!;
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    final sink = file.openWrite();
    await streamedResponse.stream.pipe(sink);
    await sink.close();

    return filePath;
  }

  Future<String> downloadAudio({
    required String audioUrl,
    required String title,
  }) async {
    final uri = Uri.parse('${ServerConstants.serverURL}/download/audio?url=$audioUrl');

    final request = http.Request('GET', uri);
    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception("Download failed with status ${streamedResponse.statusCode}");
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeTitle = title.replaceAll(RegExp(r'[\/\\:*?"<>|]'), '_');
    final fileName = "$safeTitle-$timestamp.mp3";

    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = (await getExternalStorageDirectory())!;
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    final sink = file.openWrite();
    await streamedResponse.stream.pipe(sink);
    await sink.close();

    return filePath;
  }


  @override
  Widget build(BuildContext context) {
    
    final box = Hive.box<SongModel>('offlineSongs');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                children: [
                  Text("Download Page"),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Color.fromRGBO(14, 14, 14, 1),
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 14,
                    children: [
                      CustomeField(
                        hintText: 'Paste the link',
                        controller: _textEditingController,
                      ),

                      /// DOWNLOAD AUDIO BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            final url = _textEditingController.text.trim();
                            if (url.isEmpty) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Downloading audio...")),
                            );

                            try {
                              final path = await downloadAudio(
                                audioUrl: url,
                                title: "audio_${DateTime.now().millisecondsSinceEpoch}",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Audio saved at $path")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          child: const Text(
                            'Download Audio',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),

                      /// DOWNLOAD VIDEO BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            final url = _textEditingController.text.trim();
                            if (url.isEmpty) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Downloading video...")),
                            );

                            try {
                              final path = await downloadVideo(
                                videoUrl: url,
                                title: "video_${DateTime.now().millisecondsSinceEpoch}",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Video saved at $path")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          child: const Text(
                            'Download Video',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const Column(
                        children: [
                          Center(
                              child: Align(
                                  child: Text("After clicking on the above any download button please wait for 2 - 5 minutes to complete download depending upon the file size; as current we don't have download status button : )"))),
                        ],
                      ),
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
                                    final index = downloadedSongs.indexOf(song);
                                    ref.read(playlistControllerProvider.notifier).loadSongs(downloadedSongs, source: SongSourceType.downloads);
                                    ref.read(playlistControllerProvider.notifier).playSongByIndex(index);
                                    // ref.read(currentSongNotifierProvider.notifier).updateSong(song);
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
