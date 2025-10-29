import 'dart:io';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/providers/playlist_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/AppSnakBar.dart';
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
    final playlistState = ref.watch(playlistControllerProvider);
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    final currentSong = ref.watch(currentSongNotifierProvider);

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
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                          "Downloaded Songs",
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Row(
                        spacing: 6,
                        children: [
                          IconButton(
                              onPressed: () {
                                final downloadedSongs = box.values.where((song) => song.isDownload).toList();
                                if (downloadedSongs.isNotEmpty) {
                                  playlistCtrl.loadSongs(downloadedSongs, source: SongSourceType.downloads);
                                  playlistCtrl.toggleShuffle(
                                      downloadedSongs,
                                      SongSourceType.downloads
                                  );

                                  final isShuffle = playlistState.shuffleMode == ShuffleModeType.random
                                  && playlistState.currentSource == SongSourceType.downloads;
                                  AppSnackBar.show(
                                    context,
                                    message: isShuffle
                                        ? "Shuffle mode is ON for Downloaded Songs"
                                        : "Shuffle mode is OFF",
                                    icon: Icons.download_done_rounded,
                                    backgroundColor: isShuffle
                                        ? Colors.green.shade600
                                        : Colors.orange.shade700,
                                  );
                                }
                              },
                              icon: Icon(
                                  Icons.shuffle_rounded,
                                color: (
                                    playlistState.shuffleMode == ShuffleModeType.random &&
                                        playlistState.currentSource == SongSourceType.downloads
                                )
                                  ? Pallete.gradient2
                                    : Pallete.whiteColor,
                              ),
                            iconSize: 50,
                          ),
                          IconButton(
                              onPressed: () {
                                final downloadedSongs = box.values
                                    .where((song) => song.isDownload)
                                    .toList();
                                if (downloadedSongs.isEmpty) return;
                                if(!playlistCtrl.isCurrentSource(SongSourceType.downloads)) {
                                  playlistCtrl.loadSongs(
                                      downloadedSongs,
                                    source: SongSourceType.downloads
                                  );
                                }
                                final current = ref.read(currentSongNotifierProvider);
                                if (current != null && current.id == downloadedSongs[0].id) {
                                  ref.read(currentSongNotifierProvider.notifier).playPause();
                                } else {
                                  playlistCtrl.playSongByIndex(0);
                                }
                              },
                              iconSize: 50,
                              icon: Icon(
                                  currentSong?.isPlaying ?? false
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded
                              )
                          )
                        ],
                      )
                    ],
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
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Pallete.cardColor,
                                    backgroundImage: song.localThumbnailPath != null
                                        ? FileImage(File(song.localThumbnailPath!))
                                        : null,
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
                                     playlistCtrl.loadSongs(downloadedSongs, source: SongSourceType.downloads);
                                     playlistCtrl.playSongByIndex(index);
                                     // ref.read(currentSongNotifierProvider.notifier).updateSong(song);
                                  },
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
