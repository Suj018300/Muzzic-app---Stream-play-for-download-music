import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/providers/current_song_notifier.dart';
import '../../core/theme/app_pallet.dart';
import '../home/models/song_model.dart';

class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({super.key});

  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage> {
  final TextEditingController _textEditingController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {

    final box = Hive.box<SongModel>('offlineSongs');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text("Offline Player Page"),
            ElevatedButton(
              onPressed: () {
              // Reload the page and check again when button pressed
                Navigator.pushReplacementNamed(context, '/check');
              },
              child: const Text("Check connection"),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
            slivers: [

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
                                  // trailing: PopupMenuButton(
                                  //     color: Pallete.cardColor,
                                  //     shadowColor: Pallete.gradient3,
                                  //     itemBuilder: (BuildContext context) =>
                                  //     [
                                  //       PopupMenuItem(
                                  //           onTap: () async {
                                  //             deleteDownloadedSong(song.id);
                                  //           },
                                  //           child: const Row(
                                  //             children: [
                                  //               Icon(Icons.remove),
                                  //               Text('Remove from downloads'),
                                  //             ],
                                  //           )
                                  //       ),
                                  //     ]
                                  // ),
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
